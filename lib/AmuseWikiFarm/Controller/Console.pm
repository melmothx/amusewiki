package AmuseWikiFarm::Controller::Console;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Console - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

In this namespace we manage remote gits. So not logged in can't enter
here.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->user_exists) {
        return 1;
    }
    else {
        $c->session(redirect_after_login => $c->request->path);
        $c->response->redirect($c->uri_for('/login'));
        return;
    }
}

=head2 root

Empty base method for chaining

=cut

sub root :Chained('/') :PathPart('console') :CaptureArgs(0) {}

sub console :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    die "wtf?" unless $c->user_exists;
    my @remotes = $c->stash->{site}->remote_gits;
    unless ($c->check_user_roles('root')) {
    }
    $c->stash(remotes => \@remotes);
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
