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
use AmuseWikiFarm::Log::Contextual;
use constant { MAXLENGTH => 255, MINPASSWORD => 7 };

sub login :Chained('/site_no_auth') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;
    if ($c->user_exists) {
        $c->flash(status_msg => $c->loc("You are already logged in"));
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    $c->forward('/redirect_to_secure');

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
                $c->change_session_id;
                $c->session(i_am_human => 1);
                $c->flash(status_msg => $c->loc("You are logged in now!"));
                $c->detach('redirect_after_login');
            }
        }
    }
    $c->flash(error_msg => $c->loc("Wrong username or password"));
}

sub logout :Chained('/site') :PathPart('logout') :Args(0) {
    my ($self, $c) = @_;
    if ($c->user_exists) {
        $c->logout;
        $c->flash(status_msg => $c->loc('You have logged out'));
    }
    $c->response->redirect($c->uri_for('/login'));
}

sub human :Chained('/site') :PathPart('human') :Args(0) {
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
            $c->detach('redirect_after_login');
        }
        else {
            $c->flash(error_msg => $c->loc('Wrong answer!'));
        }
    }
}

sub language :Chained('/site') :PathPart('set-language') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if ($site->multilanguage) {
        my $locale = $site->locale;
        if (my $lang = $c->request->params->{lang}) {
            if ($site->known_langs->{$lang}) {
                $locale = $lang;
                $c->session(user_locale => $locale);
            }
        }
    }
    my $goto = '/';
    # when reloading the page, go to / if we are in an /special/index page
    if (my $path = $c->request->params->{goto}) {
        if ($path !~ m%^special/index%) {
            $goto .= $path;
        }
    }
    $c->response->redirect($c->uri_for($goto));
}

sub user :Chained('/site') :CaptureArgs(0) {
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
        my %to_validate;
        log_debug { "Validating the paramaters" };
        my $missing = 0;
        foreach my $f (qw/username password passwordrepeat
                          email emailrepeat/) {
            if (my $v = $params{$f}) {
                $to_validate{$f} = $params{$f};
            }
            else {
                log_debug { $f . " is missing in the params" };
                $missing++;
            }
        }
        if ($missing) {
            $c->flash(error_msg => $c->loc('Some fields are missing, all are required'));
            return;
        }
        my $users = $c->model('DB::User');
        my ($insert, @errors) = $users->validate_params(%to_validate);
        my %insertion;

        if ($insert and !@errors) {
            %insertion = %$insert;
        }
        else {
            $c->flash(error_msg => join ("\n", map { $c->loc($_) } @errors));
            return;
        }
        die "shouldn't happen" unless $insertion{username};

        # at this point we should be good, if the user doesn't exist
        if ($users->find({ username => $insertion{username} })) {
            $c->flash(error_msg => $c->loc('Such username already exists'));
            return;
        }
        $insertion{created_by} = $c->user->get('username');
        Dlog_debug { "user insertion is $_" } \%insertion;

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
            log_info { "Sending mail from $mail_from to " . $user->email };
            if (my $usercc = $c->user->get('email')) {
                if (my $cc = Email::Valid->address($usercc)) {
                    $mail{cc} = $cc;
                    log_info { "Adding CC: $cc" };
                }
            }
            $c->stash(
                      email => \%mail,
                      password => $insertion{password},
                     );
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
    my ($self, $c, $id) = @_;
    unless ($c->user->get('id') eq $id or
            $c->check_user_roles(qw/root/)) {
        $c->detach('/not_permitted');
        return;
    }
    my $users = $c->model('DB::User');
    my $user = $users->find($id);
    unless ($user) {
        log_info { "User $id not found!" };
        $c->detach('/not_found');
        return;
    }
    my %params = %{ $c->request->params };
    if ($params{update}) {
        my %validate;
        my @msgs;
        if ($params{passwordrepeat} && $params{password}) {
            $validate{passwordrepeat} = $params{passwordrepeat};
            $validate{password} = $params{password};
            push @msgs, $c->loc("Password updated");
        }
        # email
        if ($params{emailrepeat} && $params{email}) {
            $validate{emailrepeat} = $params{emailrepeat};
            $validate{email} = $params{email};
            push @msgs, $c->loc("Email updated");
        }
        my ($validated, @errors) = $users->validate_params(%validate);
        if ($validated and %$validated) {
            $user->update($validated);
            $user->discard_changes;
            $c->flash(status_msg => join("\n", @msgs));
        }
        if (@errors) {
            $c->flash(error_msg => join("\n", map { $c->loc($_) } @errors));
        }
    }
    $c->stash(user => $user);
}

sub redirect_after_login :Private {
    my ($self, $c) = @_;
    my $path = $c->request->params->{goto} || '/';
    if ($path !~ m!^/!) {
        $path = "/$path";
    }
    $c->response->redirect($c->uri_for($path));
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
