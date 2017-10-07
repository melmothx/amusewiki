package AmuseWikiFarm::Role::Controller::HumanLoginScreen;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;
use AmuseWikiFarm::Log::Contextual;

sub get_secure_uri {
    my ($self, $c) = @_;
    my $uri = $c->request->uri->clone;
    $uri->scheme('https') if $c->stash->{site}->https_available;
    return $uri;
}

sub redirect_to_secure :Private {
    my ($self, $c) = @_;
    if ($c->request->secure) {
        if ($c->sessionid && $c->session->{switched_to_ssl}) {
            delete $c->session->{switched_to_ssl};
            Dlog_info {
                $c->request->uri . " has session " . $c->sessionid
                  . " but requested an insecure uri: $_, changing session id now"
              } $c->session;
            $c->change_session_id;
        }
        return;
    }
    my $site = $c->stash->{site};
    if ($site->secure_site || $site->secure_site_only) {
        if ($c->sessionid) {
            $c->session(switched_to_ssl => 1);
        }
        $c->response->redirect($self->get_secure_uri($c));
        $c->detach();
    }
}

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
        my $ssl_warning;
        if ($site->https_available && !$c->request->secure ) {
            log_warn {
                $c->request->uri
                  . ": $username is providing auth details, but over a plain connection"
                  . " login denied ";
            };
            $ssl_warning = $c->loc("You sent credentials over an unencrypted connection. Please switch to HTTPS, login, and change your password right away. This shouldn't happen.");

        }
        elsif (my $user = $c->model('DB::User')->find({ username => $username  })) {
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
                            # we don't need to validate this, because
                            # it's validated back in the root
                            # controller.
                            user_locale => $user->preferred_language,
                           );
                # continue now
                return 1;
            }
            log_info { "User $username not authorized" };
        }
        else {
            log_info { "Unknown user $username" };
        }
        $c->flash( error_msg => $ssl_warning || $c->loc("Wrong username or password") );
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
    my $login_target_action = '';
    my $secure_login_url = $self->get_secure_uri($c)->as_string;
    if ($secure_login_url ne $c->request->uri->as_string) {
        log_debug { "Turned " . $c->request->uri . " into $secure_login_url"};
        $login_target_action = $secure_login_url;
    }
    $c->stash(login_target_action => $login_target_action);
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
