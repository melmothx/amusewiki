package AmuseWikiFarm::Role::Controller::HumanLoginScreen;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;
use AmuseWikiFarm::Log::Contextual;

sub check_site_id_in_session :Private {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if (my $sid = $c->session->{site_id}) {
        if ($sid ne $site->id) {
            log_error {
                "$sid ne " . $site->id . " trying to access"
                  .  $c->request->uri . " deleting session"
              };
            $c->delete_session;
            die "This shouldn't happen" if $c->user_exists;
            $c->session(site_id => $site->id);
        }
    }
    $c->session(site_id => $site->id);
}

sub try_to_authenticate :Private {
    my ($self, $c) = @_;
    return 1 if $c->user_exists;
    $self->check_site_id_in_session($c);
    log_debug { "Checking login against " . $c->sessionid };
    my $site = $c->stash->{site};
    my %params = %{$c->req->body_params};

    my $form_auth;
    my ($username, $password) = @params{qw(__auth_user __auth_pass)};

    # try the HTTP basic
    if ($username || $password) {
        $form_auth = 1;
    }
    else {
        log_debug { "Trying HTTP Basic auth" };
        ($username, $password) = $c->req->headers->authorization_basic;
    }

    if ($username && $password) {
        $username .= '';
        $password .= '';
        if (my $user = $c->model('DB::User')->find({ username => $username  })) {
            log_debug { "User $username found" };
            # authenticate only if the user is a superuser
            # or if the site id matches the current site id
            if (($user->sites->find($site->id) or
                 $user->roles->find({ role => 'root' })) and
                $user->active and
                $user->check_password($password)) {
                # we're good
                if ($form_auth) {
                    die "This shouldn't happen, we checked the password"
                      unless $c->authenticate({ username => $username,
                                                password => $password });
                    $c->change_session_id;
                    $c->flash(status_msg => $c->loc("You are logged in now!"));
                }
                $c->session(i_am_human => 1,
                            site_id => $site->id,
                           );
                # continue now
                return 1;
            }
            log_info { "User $username not authorized" };
        }
        else {
            log_info { "Unknown user $username" };
        }
        $c->flash(error_msg => $c->loc("Wrong username or password"));
    }
    my @carry_on;
    foreach my $name (keys %params) {
        next if $name =~ m/^__/;
        if (ref($params{$name})) {
            push @carry_on, map { +{ name => $name, value => $_ } } @{$params{$name}};
        }
        else {
            push @carry_on, { name => $name, value => $params{$name} };
        }
    }
    $c->stash(inherit_params => \@carry_on) if @carry_on;
    return 0;
}

sub check_login :Private {
    my ($self, $c) = @_;
    if ($self->try_to_authenticate($c)) {
        return 1;
    }
    else {
        $self->set_www_authenticate($c);
        $c->stash(template => 'user/login.tt',
                  nav => 'login',
                  page_title => $c->loc('Login'));
        $c->detach();
    }
    die "Unreachable";
}

sub set_www_authenticate :Private {
    my ($self, $c) = @_;
    my $path = $c->req->uri->path;
    if ($path ne '/login' and
        $path ne '/human') {
        $c->res->status(401);
        my $ua = $c->stash->{amw_user_agent};
        my $canonical = $c->stash->{site}->canonical;
        my $auth_method;
        if (!$ua->browser_string || $ua->robot) {
            $auth_method = qq{Basic realm="$canonical"};
        }
        else {
            $auth_method = qq{FormBasedLogin realm="$canonical", comment="use form to log in"};
        }
        $c->response->headers->push_header('WWW-Authenticate' => $auth_method);
    }
}

sub check_human :Private {
    my ($self, $c) = @_;
    if ($c->sessionid && $c->session->{i_am_human}) {
        return 1;
    }
    if ($self->try_to_authenticate($c)) {
        return 1;
    }
    Dlog_debug { "Checking humanity for " . $c->sessionid  . ' with ' . $_ }
      $c->request->body_params;
    my $site = $c->stash->{site};
    if (my $answer = $site->magic_answer) {
        if (my $user_answer = $c->request->body_params->{__auth_human}) {
            if ($user_answer eq $answer) {
                log_debug { "Checking humanity is OK, storing in session " . $c->sessionid };
                $c->session(i_am_human => 1);
                return 1;
            }
            else {
                log_debug { "Checking humanity failed, $answer != $user_answer is OK" };
                $c->flash(error_msg => $c->loc('Wrong answer!'));                
            }
        }
        else {
            Dlog_debug { "No auth found: $_"} $c->request->body_params;
        }
    }
    else {
        log_error { $site->id . " is without a magic answer!" };        
    }
    # failure
    $self->set_www_authenticate($c);
    $c->stash(template => 'user/human.tt',
              page_title => $c->loc('Please prove you are a human'));
    $c->detach();
}


1;
