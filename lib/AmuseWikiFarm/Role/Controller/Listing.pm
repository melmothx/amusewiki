package AmuseWikiFarm::Role::Controller::Listing;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;

requires qw/select_texts/;

use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Log::Contextual;

sub filter_texts :Chained('select_texts') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $texts_rs = delete $c->stash->{texts};
    my $site = $c->stash->{site};
    if ($c->user_exists) {
        $texts_rs = $texts_rs->status_is_published_or_deferred;
    }
    elsif ($site->show_preview_when_deferred) {
        $texts_rs = $texts_rs->status_is_published_or_deferred_with_teaser;
    }
    else {
        $texts_rs = $texts_rs->status_is_published;
    }
    # handle the query parameters. The RS validate them
    my $query = $c->request->query_params;
    my $texts = $texts_rs
      ->order_by($query->{sort} || $site->titles_category_default_sorting)
      ->page_number($query->{page})
      ->rows_number($query->{rows} || $site->pagination_size_category);

    if (!$c->user_exists and $site->show_preview_when_deferred) {
        $c->stash(no_full_text_if_not_published => 1);
    }
    $c->stash(texts => $texts);
}

sub _stash_pager {
    my ($self, $c, $action, @args) = @_;
    my $pager = $c->stash->{texts}->pager;
    my $site = $c->stash->{site};
    my ($rows, $sort);
    my $active_rows = $pager->entries_per_page;
    my $active_sort = $site->validate_text_category_sorting($c->request->query_params->{sort} ||
                                                            $site->titles_category_default_sorting);
    if ($c->request->query_params->{rows}) {
        $rows = $active_rows;
    }
    if (my $qsort = $c->request->query_params->{sort}) {
        $sort = $active_sort;
    }
    my $format_link = sub {
        return $c->uri_for_action($action,
                                  \@args, {
                                           page => $_[0],
                                           ($rows ? (rows => $rows) : ()),
                                           ($sort ? (sort => $sort) : ()),
                                          });
    };
    my (@sortings, @rows_per_page);
    foreach my $s ($site->titles_available_sortings) {
        if ($s->{name} eq $active_sort) {
            $s->{active} = 1;
        }
        push @sortings, $s;
    }
    my @sizes = (10, 20, 50, 100, 200, 500);
    unless (grep  { $_ == $active_rows } @sizes) {
        push @sizes, $active_rows;
        @sizes = sort { $a <=> $b } @sizes;
    }
    foreach my $i (@sizes) {
        push @rows_per_page, {
                              rows => $i,
                              active => ($i == $active_rows ? 1 : 0),
                             };
    }
    Dlog_debug { "widget : $_ " } \@sortings;
    $c->stash(
              pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              pagination_widget => {
                                    target => $c->uri_for_action($action, \@args),
                                    sortings => \@sortings,
                                    rows => \@rows_per_page,
                                   },
             );
}


1;
