package AmuseWikiFarm::Controller::Tasks;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Tasks - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

Deny access to not-human

=cut

sub root :Chained('/site') :PathPart('tasks') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    unless ($c->sessionid && $c->session->{i_am_human}) {
        $c->response->redirect($c->uri_for('/human', { goto => $c->req->path }));
        $c->detach();
    }
}

sub status :Chained('root') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    my $job = $c->stash->{site}->jobs->find($id);
    unless ($job) {
        $c->detach('/not_found');
        return;
    }

    # here we inject the message, depending on the task

    my $data = $job->as_hashref;
    $data->{status_loc} = $c->loc($data->{status});

    if ($data->{produced}) {
        $data->{produced_uri} = $c->uri_for($data->{produced})->as_string;
    }
    if ($data->{sources}) {
        $data->{sources} = $c->uri_for($data->{sources})->as_string;
    }
    if (my $msg = $data->{message}) {
        # $c->loc('Your file is ready');
        # $c->loc('Changes applied');
        # $c->loc('Done');
        $data->{message} = $c->loc($msg);
    }
    $c->stash(
              job => $data,
              page_title => $c->loc('Queue'),
             );
}

sub display :Chained('status') :PathPart('') :Args(0) {
    # empty to close the chain
}

sub ajax :Chained('status') :PathPart('ajax') :Args(0) {
    my ($self, $c, $job) = @_;
    $c->stash(json => delete($c->stash->{job}));
    $c->detach($c->view('JSON'));
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
