package AmuseWikiFarm::Controller::Category;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;
use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Log::Contextual;

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

sub legacy_topics :Chained('root') :PathPart('topics') :Args {
    my ($self, $c, @args) = @_;
    $c->detach(legacy_category =>  [ topic => @args ]);
}

sub legacy_authors :Chained('root') :PathPart('authors') :Args {
    my ($self, $c, @args) = @_;
    $c->detach(legacy_category => [ author => @args ]);
}

sub legacy_category :Private {
    my ($self, $c, @args) = @_;
    my $uri;
    my %map = (
               1 => 'category_list_display',
               2 => 'single_category_display',
               3 => 'single_category_by_lang_display',
              );
    if (my $action = $map{scalar(@args)}) {
        $c->response->redirect($c->uri_for_action("/category/$action", \@args),
                               301);
        $c->detach;
    }
    else {
        $c->detach('/not_found');
    }
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
    my $row_sorting = [qw/sorting_pos name/];
    if (my $sorting = $c->req->params->{sorting}) {
        if ($sorting eq 'count-desc') {
            $row_sorting = { -desc => [ text_count => @$row_sorting] };
        }
        elsif ($sorting eq 'count-asc') {
            $row_sorting = { -asc => [ text_count => @$row_sorting] };
        }
        elsif ($sorting eq 'desc') {
            $row_sorting = { -desc => [ @$row_sorting ]};
        }
    }
    my $list = $c->stash->{categories_rs}->search(undef, { order_by => $row_sorting })->listing_tokens;
    Dlog_debug { "List is $_" } $list;

    $c->stash(list => $list,
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
        my $page = $c->request->query_params->{page};
        unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
            $page = 1;
        }
        my $texts = $cat->titles->published_texts->search(undef, { rows => 10, page => $page });
        # if it's a blog, the alphabetica entry is not so important,
        # and we give precedence to latest first.
        if ($c->stash->{blog_style}) {
            $texts = $texts->sort_by_pubdate_desc;
        }
        else {
            $c->stash(listing_item_hide_dates => 1);
        }

        my $current_locale = $c->stash->{current_locale_code};
        my $category_description = $cat->localized_desc($current_locale);
        # the unescaping happens when calling $c->loc
        my $page_title = $c->loc($cat->name);
        $c->stash(page_title => $page_title,
                  template => 'category-details.tt',
                  texts => $texts,
                  category_canonical_name => $canonical,
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
                         active => $c->stash->{site}->multilanguage ? 1 : 0,
                        };
        $c->stash(multilang => $multi);
    }
    else {
        $c->stash(uri => $canonical);
        $c->detach('/not_found');
    }
}


sub single_category_display :Chained('single_category') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $pager = $c->stash->{texts}->pager;
    my @args = ($c->stash->{f_class},
                $c->stash->{category_canonical_name});
    my $format_link = sub {
        return $c->uri_for_action('/category/single_category_display',
                                  \@args, { page => $_[0] });
    };
    $c->stash(pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link));
}

sub single_category_by_lang :Chained('single_category') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $lang) = @_;
    my $texts = delete $c->stash->{texts};
    if ($lang eq 'edit' or $lang eq 'delete') {
        $c->response->redirect($c->uri_for_action('/category/edit_category_description',
                                                  [
                                                   $c->stash->{f_class},
                                                   $c->stash->{category_canonical_name},
                                                   $c->stash->{current_locale_code},
                                                  ]));
        return;
    }
    elsif (my $category_lang = $c->stash->{site}->known_langs->{$lang}) {
        my $category_description = $c->stash->{category}->localized_desc($lang);
        my $filtered = $texts->search({ lang => $lang });
        $c->stash(
                  texts => $filtered,
                  category_language => $lang,
                  category_description => $category_description,
                 );
        $c->stash->{multilang}->{filtered} = $category_lang;
        $c->stash->{multilang}->{code} = $lang;
        $c->stash->{multilang}->{active} = 1;
        if ($c->stash->{multilang}->{code} ne $c->stash->{multilang}->{default_lang_code}) {
            $c->stash->{multilang}->{cat_uri_selected} =
              $c->uri_for_action('/category/single_category_by_lang_display',
                                 [ $c->stash->{f_class}, $c->stash->{category_canonical_name}, $lang ]);
        }
    }
    else {
        $c->detach('/not_found');
    }
}

sub single_category_by_lang_display :Chained('single_category_by_lang') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $pager = $c->stash->{texts}->pager;
    my @args = ($c->stash->{f_class},
                $c->stash->{category_canonical_name},
                $c->stash->{category_language});

    my $format_link = sub {
        return $c->uri_for_action('/category/single_category_by_lang_display',
                                  \@args, { page => $_[0] });
    };
    $c->stash(pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link));
}

sub category_editing_auth :Chained('single_category_by_lang') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists) {
        $c->response->redirect($c->uri_for('/login',
                                           { goto => $c->req->path }));
        $c->detach;
        return;
    }
}

sub edit_category_description :Chained('category_editing_auth') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    my $lang = $c->stash->{category_language};
    if ($lang && $c->request->body_params->{update}) {
        if (my $muse = $c->request->body_params->{desc_muse}) {
            $c->stash->{category}->category_descriptions
              ->update_description($lang, $muse, $c->user->get('username'));
        }
        my $dest = $c->uri_for_action('/category/single_category_by_lang_display',
                                      [ $c->stash->{f_class},
                                        $c->stash->{category}->uri,
                                        $lang,
                                      ]);
        $c->response->redirect($dest);
        $c->detach();
        return;
    }
    else {
        $c->stash(template => 'category-details-edit.tt');
    }
}

sub delete_category_by_lang :Chained('category_editing_auth') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    my @args = ($c->stash->{f_class},
                $c->stash->{category_canonical_name},
                $c->stash->{category_language});
    my $action = '/category/single_category_by_lang_display';
    if ($c->request->body_params->{delete}) {
        if (my $cat = $c->stash->{category_description}) {
            log_info { "Deleting description for " . $cat->category->name .
                         " (" . $cat->lang . ") by " . $c->user->get('username')};

            $cat->delete;
        }
    }
    else {
        # it's a get, bounce to edit
        $action = '/category/edit_category_description';
    }
    my $ret = $c->uri_for_action($action, \@args);
    $c->response->redirect($ret);
}


=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
