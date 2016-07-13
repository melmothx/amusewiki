package AmuseWikiFarm::Controller::Latest;
use utf8;
use Moose;
with qw/AmuseWikiFarm::Role::Controller::RegularListing/;

use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paginator;

=head1 NAME

AmuseWikiFarm::Controller::Latest - Catalyst Controller for latest entries.

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 pre_base

=cut

sub pre_base :Chained('/site_robot_index') :PathPart('latest') :CaptureArgs(0) {}

sub index :Chained('base') :PathPart('') :Args {
    my ($self, $c, $page) = @_;
    log_debug { "requested /latest/ $page" };
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    my $site = $c->stash->{site};
    my $results = $c->stash->{texts_rs}->search(undef,
                                                {
                                                 order_by => { -desc => 'pubdate' },
                                                 page => $page,
                                                 rows => $site->pagination_size,
                                                });
    my $pager = $results->pager;
    my $format_link = sub {
        return $c->uri_for_action('/latest/index', $_[0]);
    };
    $c->stash(pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              nav => 'latest',
              page_title => $c->loc('Latest entries'),
              texts => $results);
    if ($c->request->query_params->{bare}) {
        $c->stash(no_wrapper => 1);
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
