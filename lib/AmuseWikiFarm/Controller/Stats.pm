package AmuseWikiFarm::Controller::Stats;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Stats - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub stats :Chained('/site_robot_index') :CaptureArgs(0) {}

sub popular :Chained('stats') :Args {
    my ($self, $c, $page) = @_;
    log_debug { "requested /stats/popular/ $page" };
    my $results = $c->stash->{site}->popular_titles($page);
    my $pager = $results->pager;
    my $format_link = sub {
        return $c->uri_for_action('/stats/popular', $_[0]);
    };
    my @res;
    while (my $row = $results->next) {
        push @res, $row->title;
    }
    $c->stash(pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              nav => 'popular',
              page_title => $c->loc('Popular texts'),
              texts => \@res);
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
