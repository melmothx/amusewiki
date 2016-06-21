package AmuseWikiFarm::Controller::Cloud;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;


=head1 NAME

AmuseWikiFarm::Controller::Cloud - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base :Chained('/site_robot_index') :PathPart('cloud') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $max = 1000;
    if (my $query_max = $c->request->query_params->{max}) {
        if ($query_max =~ m/\A([1-9][0-9]*)\z/) {
            $max = $1;
        }
    }
    if ($c->request->query_params->{bare}) {
        $c->stash->{no_wrapper} = 1;
    }
    my $limit = 0;
    if (my $query_limit = $c->request->query_params->{limit}) {
        if ($query_limit =~ m/\A([1-9][0-9]*)\z/) {
            $limit = $1;
        }
    }
    log_debug { "Computing cloud with min texts $limit and max result $max" };

    my $cats = $c->stash->{site}->categories->min_texts($limit)->rand($max);
    $c->stash(cloud_categories => $cats,
              template => 'cloud/show.tt');
}

sub show :Chained('base') :PathPart('') :Args(0) {}

sub authors :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{cloud_categories} = $c->stash->{cloud_categories}->authors_only;
}

sub topics :Chained('base') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{cloud_categories} = $c->stash->{cloud_categories}->topics_only;
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
