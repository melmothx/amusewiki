package AmuseWikiFarm::Controller::Search;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Search - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paginator;
use AmuseWikiFarm::Utils::Iterator;
use Data::Page;

sub opensearch :Chained('/site_no_auth') :PathPart('opensearch.xml') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1);
    $c->res->content_type('application/xml');
}

sub index :Chained('/site') :PathPart('search') :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(please_index => 1);
    my $site = $c->stash->{site};
    my $xapian = $site->xapian;
    my %params = %{$c->req->params};
    Dlog_debug { "Searching with these parameters $_" } \%params;

    my $res = $xapian->faceted_search(%params,
                                      no_facets => 1,
                                      locale => $c->stash->{current_locale_code},
                                      lh => $c->stash->{lh},
                                      site => $site);
    if (my $error = $res->error) {
        # an error is likely triggered by a wrong syntax, so a 404
        # makes sense (no results for such query)
        $c->response->status(404);
        $c->stash(search_error => $error);
    }

    if ($params{fmt} and $params{fmt} eq 'json') {
        $c->stash(json => $res->json_output);
        $c->detach($c->view('JSON'));
        return;
    }

    my $baseres = $xapian->faceted_search(%params,
                                          no_filters => 1,
                                          locale => $c->stash->{current_locale_code},
                                          lh => $c->stash->{lh},
                                          site => $site);
    if (!$c->user_exists and $site->show_preview_when_deferred) {
        $c->stash(no_full_text_if_not_published => 1);
    }
    my $format_link = sub {
        return $c->uri_for($c->action, { %params, page => $_[0] });
    };
    my $facets = $baseres->facet_tokens;
    my $has_facets = 0;
    foreach my $facet (@$facets) {
        if (@{$facet->{facets}}) {
            $has_facets = 1;
            last;
        }
    }
    $c->stash( pager => AmuseWikiFarm::Utils::Paginator::create_pager($res->pager, $format_link),
               page_title => $c->loc('Search'),
               facets => ($has_facets ? $facets : undef),
               texts => AmuseWikiFarm::Utils::Iterator->new($res->texts));
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
