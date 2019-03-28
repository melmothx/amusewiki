package AmuseWikiFarm::Controller::Feed;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Feed - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index

Path: /feed

RSS 2.0 feed, built using XML::FeedPP

=cut

sub index :Chained('/site') :PathPart('feed') :Args(0) {
    my ( $self, $c ) = @_;
    my $site = $c->stash->{site};
    my $feed = $site->get_rss_feed;
    # render and set
    $c->response->content_type('application/rss+xml');
    $c->response->header('Access-Control-Allow-Origin', '*') unless $site->is_private;
    $c->response->body($feed);
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
