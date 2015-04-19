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

sub authors :Chained('root') :PathPart('authors') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward(category_list => [qw/author/]);
}

sub topics :Chained('root') :PathPart('topics') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward(category_list => [qw/topic/]);
}

sub category_list :Private {
    my ($self, $c, $type) = @_;
    my $rs = $c->stash->{site}->categories->active_only_by_type($type);
    $c->stash(
              nav => $type,
              categories_rs => $rs,
              f_class => $type,
             );
}

sub authors_listing :Chained('authors') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Authors'));
    $c->forward('category_list_display');
}

sub topics_listing :Chained('topics') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Topics'));
    $c->forward('category_list_display');
}

sub category_list_display :Private {
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

sub single_topic :Chained('topics') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward(single_category => [$uri]);
}

sub single_author :Chained('authors') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    $c->forward(single_category => [$uri]);
}

sub single_category :Private {
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

        # the unescaping happens when calling $c->loc
        my $page_title = $c->loc($cat->name);
        $c->stash(page_title => $page_title,
                  template => 'category-details.tt',
                  texts => $texts,
                  category => $cat);

        # if the site is multilanguage, prepare the links
        if ($c->stash->{site}->multilanguage) {
            my $action_all =  "/category/single_" . $c->stash->{nav} . "_display";
            my $action_lang = "/category/single_" . $c->stash->{nav} . "_by_lang";
            my $multi = {
                         cat_uri_all => $c->uri_for_action($action_all, [ $uri ]),
                         cat_uri_lang => $c->uri_for_action($action_lang,
                                                            [
                                                             $uri,
                                                             $current_locale,
                                                            ]),
                         cat_lang_name => $c->stash->{current_locale_name},
                         default_lang_code => $current_locale,
                        };
            $c->stash(multilang => $multi);
        }
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}


sub single_topic_display :Chained('single_topic') :PathPart('') :Args(0) {}

sub single_author_display :Chained('single_author') :PathPart('') :Args(0) {}


sub single_author_by_lang :Chained('single_author') :PathPart('') :Args(1) {
    my ($self, $c, $lang) = @_;
    $c->forward(single_category_by_lang => [ $lang ]);
}

sub single_topic_by_lang :Chained('single_topic') :PathPart('') :Args(1) {
    my ($self, $c, $lang) = @_;
    $c->forward(single_category_by_lang => [ $lang ]);
}

sub single_category_by_lang :Private {
    my ($self, $c, $lang) = @_;
    my $texts = delete $c->stash->{texts};
    if (my $category_lang = $c->stash->{site}->known_langs->{$lang}) {
        my $filtered = $texts->search({ lang => $lang });
        $c->stash(texts => $filtered);
        $c->stash->{multilang}->{filtered} = $category_lang;
        $c->stash->{multilang}->{code} = $lang;
    }
    else {
        $c->detach('/not_found');
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
