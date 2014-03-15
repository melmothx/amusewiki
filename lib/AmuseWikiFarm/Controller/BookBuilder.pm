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

use Data::Dumper;

sub root :Chained('/') :PathPart('bookbuilder') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    # this is the root method. Initialize the session with the list;
    my $bblist = $c->session->{bblist} ||= [];
    my $bb = $c->model('BookBuilder')->textlist($bblist);
    $c->stash(bb => $bb);
}

sub index :Chained('root') :PathPart('') :Args(0) {}

sub status :Chained('root') :PathPart('status') :Args(0) {
    my ($self, $c) = @_;
    $c->forward('save_session');
}

sub edit :Chained('root') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
    $c->forward('save_session');
}

sub add :Chained('root') :PathPart('add') :Args(0) {
    my ( $self, $c ) = @_;
    $c->log->debug(Dumper($c->request->params));
    if (my $book = $c->request->params->{text}) {
        push @{ $c->session->{bblist} }, $book;
        $c->flash->{status_msg} = $c->loc('Text added');
        $c->response->redirect($c->uri_for_action('/library/text' => $book));
    }
    else {
        $c->response->redirect($c->uri_for('/'));
    }
    $c->forward('save_session');
}

sub save_session :Private {
    my ( $self, $c ) = @_;
    $c->log->debug('Saving books in the session');
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
