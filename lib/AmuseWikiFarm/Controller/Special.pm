package AmuseWikiFarm::Controller::Special;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Special - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for the special pages. Special pages are stored in
the DB, and use the markup only for editing, storing a local copy of
the .muse file.

=head1 METHODS

=cut


=head2 root

=head2 entry

=cut

sub root :Chained('/') :PathPart('special') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(specials => $c->model('Special'));
}

sub entry :Chained('root') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $page) = @_;
    $c->stash(special_uri => $page);
    $c->stash(edit_action => $c->uri_for_action('/special/edit', [$page]));
    $c->log->debug($c->stash->{edit_action});
    $c->stash(special_page => $c->stash->{specials}->find_page($page));
    # $c->log->debug($c->stash->{specials}->site_schema->id);
}

sub display :Chained('entry') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    # empty method, just to close the chain
}

sub edit :Chained('entry') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;

    # prevent editing from non-logged in. Don't bother to offer a
    # login page, it just should not happen.
    unless ($c->user_exists) {
        $c->detach('/not_permitted');
        return;
    }
    my $params = $c->request->params;
    my $page   = $c->stash->{special_uri};
    my $model  = $c->stash->{specials};
    my $text   = $model->edit($page => { %$params });
    if ($text) {
        $c->flash->{status_msg} = $c->loc("[_1] updated!", $page);
        $c->res->redirect($c->uri_for_action('/special/display', [$page]));
    }
    else {
        $c->flash->{error_msg} = $c->loc($model->error);
        # got an error, so don't redirect if we don't want the loser
        # to loose the param.
        $c->stash(template => 'special/display.tt');
        return;
    }
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
