package AmuseWikiFarm::Controller::BookBuilder;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::BookBuilder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/') :PathPart('bookbuilder') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # this is the root method. Initialize the session with the list;
    my $bblist = $c->session->{bblist} ||= [];

    # initialize the BookBuilder object
    my $bb = $c->model('BookBuilder');
    $bb->textlist($bblist);

    $c->stash(bb => $bb);
}

sub index :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my %params = %{ $c->request->params };
    if ($params{build} and
        $params{collectionname} =~ m/\w/ and
        @{$c->stash->{bb}->texts}) {
        $c->log->debug("Builing now");

        if (my $job = $c->stash->{bb}->enqueu($c->stash->{site}, \%params)) {
            # flush the toilet
            $c->forward('save_session');

            # and redirect to the status page
            $c->res->redirect($c->uri_for_action('/bookbuilder/status', $job));
        }
        # if we get this, the user cheated and doesn't deserve an explanation
        else {

            $c->flash->{error_msg} = $c->loc("Couldn't build that");
        }
    }
}

sub status :Chained('root') :PathPart('status') :Args(1) {
    my ($self, $c) = @_;
    $c->forward('save_session');
}

sub edit :Chained('root') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    if (my $index = $c->request->params->{textindex}) {
        $c->log->debug("Operating on $index");
        if ($c->request->params->{moveup}) {
            $c->stash->{bb}->move_up($index);
        }
        elsif ($c->request->params->{movedw}) {
            $c->stash->{bb}->move_down($index);
        }
        elsif ($c->request->params->{delete}) {
            $c->stash->{bb}->delete_text($index);
        }
    }
    $c->forward('save_session');
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub clear :Chained('root') :PathPart('clear') :Args(0) {
    my ($self, $c) = @_;
    if ($c->request->params->{clear}) {
        $c->stash->{bb}->delete_all;
        $c->forward('save_session');
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub add :Chained('root') :PathPart('add') :Args(0) {
    my ( $self, $c ) = @_;
    if (my $text = $c->request->params->{text}) {
        if ($c->stash->{bb}->add_text($text)) {
            $c->forward('save_session');
            $c->flash->{status_msg} = $c->loc('Text added');
            my $referrer = $c->uri_for_action('/library/text' => $text);
            $c->stash(referrer => $referrer);
        }
        else {
            $c->flash->{error_msg} = $c->loc("Couldn't add the text");
        }
    }
    else {
        $c->flash->{error_msg} = $c->loc("No text provided!");
    }
    $c->response->redirect($c->uri_for_action('bookbuilder/index'));
}

sub save_session :Private {
    my ( $self, $c ) = @_;
    $c->log->debug('Saving books in the session');
    $c->session->{bblist} = $c->stash->{bb}->texts;
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
