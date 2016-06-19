package AmuseWikiFarm::Controller::Cloud;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Cloud - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub base :Chained('/site_robot_index') :PathPart('cloud') :CaptureArgs(0) {}

sub show :Chained('base') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $cats = $site->categories->active_only->rand(1000);
    my @out;
    while (my $cat = $cats->next) {
        my $details = {
                       name => $cat->name,
                       full_uri => $c->uri_for($cat->full_uri),
                       text_count => $cat->text_count,
                      };
        $details->{cloud_level} = int($details->{text_count} / 5);
        if ($details->{cloud_level} > 20) {
            $details->{cloud_level} = 20;
        }
        push @out, $details;
    }
    $c->stash(cloud_categories => \@out);
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
