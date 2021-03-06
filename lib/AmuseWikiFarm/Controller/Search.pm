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
    my $lh = $c->stash->{lh};
    my $xapian = $site->xapian;
    my $user_exists = $c->user_exists;
    if ($user_exists) {
        # by default we don't show the deferred titles, unless the
        # site has the show_preview_when_deferred option set.
        # so for logged in, enforce it to true.
        $xapian->show_deferred(1);
    }
    my %params = %{$c->req->params};
    Dlog_debug { "Searching with these parameters $_" } \%params;

    my $res = $xapian->faceted_search(%params,
                                      facets => 0,
                                      filters => 1,
                                      locale => $c->stash->{current_locale_code},
                                     );
    $res->lh($lh);
    $res->site($site);

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
                                          filters => 0,
                                          facets => 1,
                                          locale => $c->stash->{current_locale_code},
                                         );
    $baseres->lh($lh);
    $baseres->site($site);

    if (!$user_exists and $site->show_preview_when_deferred) {
        $c->stash(no_full_text_if_not_published => 1);
    }
    # do a copy, because later we overwrite query.
    my %link_params = %params;
    my $format_link = sub {
        return $c->uri_for($c->action, { %link_params, page => $_[0] });
    };
    my $facets = $baseres->facet_tokens;
    my $has_facets = 0;
    foreach my $facet (@$facets) {
        if (@{$facet->{facets}}) {
            $has_facets = 1;
            last;
        }
    }
    if (my $corrected = $res->did_you_mean) {
        $params{query} = $corrected;
        $c->stash(did_you_mean => $corrected,
                  did_you_mean_url => $c->uri_for_action('/search/index', [], \%params));
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
