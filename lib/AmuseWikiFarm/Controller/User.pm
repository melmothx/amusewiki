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

use Email::Valid;

sub login :Path('/login') :Args(0) {
    my ( $self, $c ) = @_;
    if ($c->user_exists) {
        $c->flash(status_msg => $c->loc("You are already logged in"));
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    $c->stash(
              nav => 'login',
              page_title => $c->loc('Login'),
             );
    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};

    # check if the is the submit action
    return unless $c->request->params->{submit};

    unless ($username && $password) {
        $c->flash(error_msg => $c->loc("Missing username or password"));
        return;
    }
    my $site = $c->stash->{site};
    # get the details from the db before authenticate it.
    # here we have another layer befor hitting the authenticate

    if (my $user = $c->model('DB::User')->find({ username => $username })) {

        # authenticate only if the user is a superuser
        # or if the site id matches the current site id
        if (($user->sites->find($site->id) or
             $user->roles->find({ role => 'root' })) and $user->active) {

            if ($c->authenticate({ username => $username,
                                   password => $password })) {
                $c->session(site_id => $site->id);
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
    if ($c->session->{i_am_human}) {
        # wtf...
        $c->flash(status_msg => $c->loc('You already proved you are human'));
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    $c->stash(page_title => $c->loc('Please prove you are a human'));
    if ($c->request->params->{answer}) {
        if ($c->request->params->{answer} eq $c->stash->{site}->magic_answer) {
            # ok, you're a human
            $c->session(i_am_human => 1);
            my $goto = delete $c->session->{redirect_after_login};
            $goto ||= $c->uri_for('/');
            $c->response->redirect($goto);
            return;
        }
        else {
            $c->flash(error_msg => $c->loc('Wrong answer!'));
        }
    }
}


sub user :Chained('/') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists) {
        $c->detach('/not_permitted');
    }
}

sub create :Chained('user') :Args(0) {
    my ($self, $c) = @_;
    # start validating
    my %params = %{ $c->request->params };
    if ($params{create}) {
        # check if all the fields are in place
        my %insertion;
        $c->log->debug("Validating");
        my $missing = 0;
        foreach my $f (qw/username password passwordrepeat
                          email emailrepeat/) {
            $missing++ unless $params{$f};
        }
        if ($missing) {
            $c->flash(error_msg => $c->loc('Some fields are missing, all are required'));
            return;
        }

        # check username
        if ($params{username} =~ m/^([0-9a-z]+)$/) {
            $insertion{username} = $1;
        }
        else {
            $c->flash(error_msg => $c->loc('Invalid username'));
            return;
        }

        # check mail
        if (my $mail = Email::Valid->address($params{email})) {
            $insertion{email} = $mail;
        }
        else {
            $c->flash(error_msg => $c->loc('Invalid mail'));
            return;
        }

        # check password
        if (length($params{password}) > 7) {
            $insertion{password} = $params{password};
        }
        else {
            $c->flash(error_msg => $c->loc('Password too short'));
            return;
        }

        if ($insertion{password} ne $params{passwordrepeat}) {
            $c->flash(error_msg => $c->loc('Passwords do not match'));
            return;
        }

        if ($insertion{email} ne $params{emailrepeat}) {
            $c->flash(error_msg => $c->loc('Emails do not match'));
            return;
        }
        my $users = $c->model('DB::User');
        # at this point we should be good, if the user doesn't exist
        if ($users->find({ username => $insertion{username} })) {
            $c->flash(error_msg => $c->loc('Such username already exists'));
            return;
        }
        my $user = $users->create(\%insertion);
        $user->set_roles([{ role => 'librarian' }]);
        $c->stash->{site}->add_to_users($user);
        $user->discard_changes;

        $c->flash(status_msg => $c->loc("User [_1] created!", $user->username));
        $c->stash(user => $user);

        if (my $mail_from = $c->stash->{site}->mail_from) {
            my %mail = (
                        to => $user->email,
                        from => $mail_from,
                        subject => $c->loc('User created'),
                        template => 'newuser.tt'
                       );
            if (my $cc = Email::Valid->address($c->user->get('email'))) {
                $mail{cc} = $cc;
            }
            $c->stash(email => \%mail);
            $c->forward($c->view('Email::Template'));
            if (scalar(@{ $c->error })) {
                $c->flash(error_msg => $c->loc('Error sending mail!'));
            }
            else {
                $c->flash->{status_msg} .= "\n" . $c->loc('Email sent!');
            }
        }
        $c->response->redirect($c->uri_for('/'));
    }
}

sub edit :Chained('user') :Args(1) {
    my ($self, $c) = @_;
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
