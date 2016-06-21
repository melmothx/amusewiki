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

sub base :Chained('/site_robot_index') :PathPart('cloud') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $cats = $site->categories->active_only->rand(1000);
    my @out;
    while (my $cat = $cats->next) {
        my $details = {
                       name => $cat->name,
                       full_uri => $c->uri_for($cat->full_uri),
                       text_count => $cat->text_count,
                       type => $cat->type,
                      };
        $details->{cloud_level} = int($details->{text_count} / 5);
        if ($details->{cloud_level} > 20) {
            $details->{cloud_level} = 20;
        }
        push @out, $details;
    }
    $c->stash(cloud_categories => \@out);
    $c->stash(template => 'cloud/show.tt');
}

sub show :Chained('base') :PathPart('') :Args(0) {
}

sub limit :Chained('base') :CaptureArgs(1) {
    my ($self, $c, $limit) = @_;
    # filter out
    unless ($limit && $limit =~ m/\A[1-9][0-9]*\z/) {
        $limit = 0;
    }
    my @out = grep { $_->{text_count} > $limit } @{$c->stash->{cloud_categories}};
    $c->stash(cloud_categories => \@out);
}

sub limit_display :Chained('limit') :PathPart('') :Args(0) {}

sub bare :Chained('limit') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{no_wrapper} = 1;
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
