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
use URI;
use URI::QueryParam;
use AmuseWikiFarm::Log::Contextual;
use constant { MAXLENGTH => 255, MINPASSWORD => 7 };

sub login :Chained('/secure_no_user') :PathPart('login') :Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(
              nav => 'login',
              page_title => $c->loc('Login'),
             );
    my $username = $c->request->body_params->{username};
    my $password = $c->request->body_params->{password};

    # check if the is the submit action
    return unless $c->request->body_params->{submit};

    # before flashing, set the session id
    my $site = $c->stash->{site};
    log_debug { "setting site id " . $site->id . " in the session" };
    $c->session(site_id => $site->id);

    unless ($username && $password) {
        $c->flash(error_msg => $c->loc("Missing username or password"));
        return;
    }
    # force stringification
    $username .= '';
    $password .= '';

    # get the details from the db before authenticate it.
    # here we have another layer befor hitting the authenticate

    if (my $user = $c->model('DB::User')->find({ username => $username  })) {
        log_debug { "User $username found" };
        # authenticate only if the user is a superuser
        # or if the site id matches the current site id
        if (($user->sites->find($site->id) or
             $user->roles->find({ role => 'root' })) and $user->active) {

            if ($c->authenticate({ username => $username,
                                   password => $password })) {
                log_debug { "User $username successfully authenticated" };
                $c->change_session_id;
                $c->session(i_am_human => 1);
                $c->flash(status_msg => $c->loc("You are logged in now!"));
                $c->detach('redirect_after_login');
                return;
            }
        }
        log_info { "User $username not authorized" };
    }
    $c->flash(error_msg => $c->loc("Wrong username or password"));
}

sub reset_password :Chained('/secure_no_user') :PathPart('reset-password') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(
              page_title => $c->loc('Reset password'),
             );
    my $params = $c->request->body_params;
    if ($params->{submit} && $params->{email} && $params->{email} =~ m/\w/) {
        my $site = $c->stash->{site};
        foreach my $user ($site->users->set_reset_token($params->{email})) {
            log_info { "Set reset token for " . $user->username };
            my $dt = DateTime->from_epoch(epoch => $user->reset_until,
                                          locale => $c->stash->{current_locale_code});
            my $valid_until = $dt->format_cldr($dt->locale->datetime_format_long);
            my $url = $c->uri_for_action('/user/reset_password_confirm',
                                         [ $user->username, $user->reset_token ]);
            $c->model('Mailer')->send_mail(resetpassword => {
                                                             lh => $c->stash->{lh},
                                                             to => $user->email,
                                                             from => $site->mail_from_default,
                                                             reset_url => $url,
                                                             host => $site->canonical,
                                                             valid => $valid_until,
                                                             username => $user->username,
                                                            });
        }
    }
}

sub reset_password_confirm :Chained('/secure_no_user') :PathPart('reset-password') :Args(2) {
    my ($self, $c, $username, $token) = @_;
    if ($username and
        $token and
        $username =~ m/\w/ and
        $token =~ m/\w/ ) {
        if (my $password = $c->stash->{site}->users->reset_password($username, $token)) {
            $c->stash(password => $password,
                      username => $username);
        }
        else {
            log_warn { $c->request->uri . " accessed with invalid mail and token" };
            $c->detach('/not_permitted');
        }
    }
    else {
        log_error { $c->request->uri . " accessed without mail and token shouldn't happen!" };
        $c->detach('/not_permitted');
    }
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
    if ($c->sessionid && $c->session->{i_am_human}) {
        # wtf...
        $c->flash(status_msg => $c->loc('You already proved you are human'));
        $c->response->redirect($c->uri_for('/'));
        return;
    }

    $c->stash(page_title => $c->loc('Please prove you are a human'));
    # if no magic answer is provided, do nothing
    if (!$c->stash->{site}->magic_answer) {
        log_error { $c->request->uri . " is without a magic answer!" };
        return;
    }

    if ($c->request->body_params->{answer}) {
        # set the site_id before flashing again
        $c->session(site_id => $c->stash->{site}->id);
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

sub user :Chained('/site_user_required') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->user_exists) {
        log_error { $c->request->uri . " accessed without user, shouldn't happen!" };
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
            Dlog_debug { "error: insert and errors: $_" } [ $insert, @errors ];
            $c->flash(error_msg => join ("\n", map { $c->loc($_) } @errors));
            return;
        }
        die "shouldn't happen" unless $insertion{username};

        # at this point we should be good, if the user doesn't exist
        if ($users->find({ username => $insertion{username} })) {
            log_debug { "User already exists" };
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
                        lh => $c->stash->{lh},
                        to => $user->email,
                        cc => '',
                        from => $mail_from,
                        home => $c->uri_for('/'),
                        username  => $user->username,
                        password => $insertion{password},
                        create_url => $c->uri_for_action('/user/create'),
                        edit_url => $c->uri_for_action('/user/edit', [ $user->id ]),
                       );
            if (my $usercc = $c->user->get('email')) {
                if (my $cc = Email::Valid->address($usercc)) {
                    $mail{cc} = $cc;
                }
            }
            if ($c->model('Mailer')->send_mail(newuser => \%mail)) {
                $c->flash->{status_msg} .= "\n" . $c->loc('Email sent!');
            }
            else {
                $c->flash(error_msg => $c->loc('Error sending mail!'));
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

sub site_config :Chained('user') :PathPart('site') {
    my ($self, $c) = @_;
    unless ($c->check_user_roles('admin')) {
        $c->detach('/not_permitted');
        return;
    }
    my $site = $c->stash->{site};
    my $esite = $c->model('DB::Site')->find($site->id);
    my %params = %{ $c->request->body_parameters };
    if (delete $params{edit_site}) {
        Dlog_debug { "Doing the update on $_" } \%params;
        if (my $err = $esite->update_from_params_restricted(\%params)) {
            log_debug { "Error! $err" };
            $c->flash(error_msg => $c->loc($err));
        }
    }
    $c->stash(template => 'admin/edit.tt',
              load_highlight => $site->use_js_highlight(1),
              esite => $esite,
              restricted => 1);
}

sub redirect_after_login :Private {
    my ($self, $c) = @_;
    my $path = $c->request->params->{goto} || '/';
    if ($path !~ m!^/!) {
        $path = "/$path";
    }
    my $uri = URI->new($path);
    my $redirect = $c->uri_for($uri->path, $uri->query_form_hash);
    if (my $fragment = $c->request->params->{fragment}) {
        if ($fragment =~ m/\A(#[0-9A-Za-z-]+)\z/) {
            $redirect .= $1;
        }
    }
    Dlog_debug { "Redirecting $path to " . $uri->path . " " . $_
                   . " => " . $redirect } $uri->query_form_hash;
    $c->response->redirect($redirect);
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
