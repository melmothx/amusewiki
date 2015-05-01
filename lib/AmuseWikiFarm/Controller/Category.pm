package AmuseWikiFarm::Controller::Category;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;

=head1 NAME

AmuseWikiFarm::Controller::Category - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 Category listing

=head3 authors

The list of authors

=head3 authors/<name>

Details about the author <name>

=head3 topics

The list of topics

=head3 topics/<name>

=cut

sub root :Chained('/site') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(please_index => 1);
}

sub category :Chained('root') :PathPart('category') :CaptureArgs(1) {
    my ($self, $c, $type) = @_;
    if ($type eq 'topic') {
        $c->stash(page_title => $c->loc('Topics'));
    }
    elsif ($type eq 'author') {
        $c->stash(page_title => $c->loc('Authors'));
    }
    else {
        $c->detach('/not_found');
        return;
    }
    my $rs = $c->stash->{site}->categories->active_only_by_type($type);
    $c->stash(
              nav => $type,
              categories_rs => $rs,
              f_class => $type,
             );
}

sub category_list_display :Chained('category') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $site_id = $c->stash->{site}->id;
    my $rs = delete $c->stash->{categories_rs};
    my $cache = $c->model('Cache',
                          site_id => $site_id,
                          type => 'category',
                          subtype => $c->stash->{f_class},
                          lang => $c->stash->{current_locale_code},
                          resultset => $rs);

    # this should be safe.
    my @list = @{ $cache->texts };

    if (my $sorting = $c->req->params->{sorting}) {
        if ($sorting eq 'count-desc') {
            @list = sort { $b->{text_count} <=> $a->{text_count} } @list;
        }
        elsif ($sorting eq 'count-asc') {
            @list = sort { $a->{text_count} <=> $b->{text_count} } @list;
        }
        elsif ($sorting eq 'desc') {
            @list = reverse @list;
        }
    }
    $c->stash(list => \@list,
              template => 'category.tt');
}

sub single_category :Chained('category') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    my $canonical = muse_naming_algo($uri);
    my $cat = $c->stash->{categories_rs}->find({ uri => $canonical });
    if ($cat) {
        if ($cat->uri ne $uri) {
            $c->response->redirect($c->uri_for($cat->full_uri));
            $c->detach();
            return;
        }
        my $texts = $cat->titles->published_texts;
        my $current_locale = $c->stash->{current_locale_code};
        my $category_description = $cat->localized_desc($current_locale);
        # the unescaping happens when calling $c->loc
        my $page_title = $c->loc($cat->name);
        $c->stash(page_title => $page_title,
                  template => 'category-details.tt',
                  texts => $texts,
                  category_description => $category_description,
                  category => $cat);

        # Prepare the links for multisite, if needed
        my $multi = {
                         cat_uri_all => $c->uri_for_action('/category/single_category_display',
                                                           [ $c->stash->{f_class}, $uri ]),
                         cat_uri_lang => $c->uri_for_action('/category/single_category_by_lang_display',
                                                            [
                                                             $c->stash->{f_class},
                                                             $uri,
                                                             $current_locale,
                                                            ]),
                         cat_lang_name => $c->stash->{current_locale_name},
                         default_lang_code => $current_locale,
                        };
        $c->stash(multilang => $multi);
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}


sub single_category_display :Chained('single_category') :PathPart('') :Args(0) {}

sub single_category_by_lang :Chained('single_category') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $lang) = @_;
    my $texts = delete $c->stash->{texts};
    if (my $category_lang = $c->stash->{site}->known_langs->{$lang}) {
        my $filtered = $texts->search({ lang => $lang });
        $c->stash(
                  texts => $filtered,
                  category_language => $lang,
                 );
        $c->stash->{multilang}->{filtered} = $category_lang;
        $c->stash->{multilang}->{code} = $lang;
    }
    else {
        $c->detach('/not_found');
    }
}

sub single_category_by_lang_display :Chained('single_category_by_lang') :PathPart('') :Args(0) {}

sub edit_category_description :Chained('single_category_by_lang') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists) {
        $c->response->redirect($c->uri_for('/login',
                                           { goto => $c->req->path }));
        $c->detach;
        return;
    }
    my $lang = $c->stash->{category_language};
    if ($lang && $c->request->body_params->{update}) {
        if (my $muse = $c->request->body_params->{desc_muse}) {
            $c->stash->{category}->category_descriptions
              ->update_description($lang, $muse);
        }
        my $dest = $c->uri_for_action('/category/single_category_display', [ $c->stash->{f_class},
                                                                             $c->stash->{category}->uri ]);
        $c->response->redirect($dest);
        $c->detach();
        return;
    }
    else {
        $c->stash(template => 'category-details-edit.tt');
    }
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
