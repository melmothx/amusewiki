package AmuseWikiFarm::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

Canonical methods to login and logout users

=cut

=head2 login

Path: /login

Upon login, first the username is checked. We don't call the
authenticate method if the user does not exists, or if it belongs to
another site.

Also, it install the C<i_am_human> token in the session, so even after
logout, the user is still marked as human.

=head2 logout

Path: /logout

Log the user out, but do not reset the session.

=head2 human

Path: /human

Url where the form for the antispam question should be posted. It
install in the session the key C<i_am_human>.

=cut

sub login :Path('/login') :Args(0) {
    my ( $self, $c ) = @_;
    if ($c->user_exists) {
        $c->flash(status_msg => $c->loc("You are already logged in"));
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};

    # check if the is the submit action
    return unless $c->request->params->{submit};

    unless ($username && $password) {
        $c->flash(error_msg => $c->loc("Missing username or password"));
        return;
    }
    # get the details from the db before authenticate it.
    # here we have another layer befor hitting the authenticate
    if (my $user = $c->find_user({ username => $username })) {

        # authenticate only if the user doesn't belong to any specific file
        # or if the site id matches the current site id
        if (!$user->site or
            $user->site->id eq $c->stash->{site}->id) {
            # ok, let'd go
            if ($c->authenticate({ username => $username,
                                   password => $password })) {

                $c->session(i_am_human => 1);
                $c->flash(status_msg => $c->loc("You are logged in now!"));

                my $goto = delete $c->session->{redirect_after_login};
                $goto ||= $c->uri_for('/');
                $c->response->redirect($goto);
                return;
            }
        }
    }
    $c->flash(error_msg => $c->loc("Wrong username or password"));
}

sub logout :Path('/logout') :Args(0) {
    my ($self, $c) = @_;
    if ($c->user_exists) {
        $c->logout;
        $c->flash(status_msg => $c->loc('You have logged out'));
    }
    $c->response->redirect($c->uri_for('/login'));
}

sub human :Path('/human') :Args(0) {
    my ($self, $c) = @_;
    $c->response->body('Are you human?');
    # $c->session(i_am_human => 1);
}

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
