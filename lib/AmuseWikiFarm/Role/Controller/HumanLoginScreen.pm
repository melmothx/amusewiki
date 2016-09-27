package AmuseWikiFarm::Role::Controller::HumanLoginScreen;

use strict;
use warnings;

use MooseX::MethodAttributes::Role;
use AmuseWikiFarm::Log::Contextual;

sub try_to_authenticate :Private {
    my ($self, $c) = @_;
    return 1 if $c->user_exists;
    my $site = $c->stash->{site};

    $c->session(site_id => $site->id);

    log_debug { "Checking login against " . $c->sessionid };
    my %params = %{$c->req->body_params};
    my ($username, $password) = @params{qw(__auth_user __auth_pass)};
    if ($username && $password) {
        $username .= '';
        $password .= '';
        if (my $user = $c->model('DB::User')->find({ username => $username  })) {
            log_debug { "User $username found" };
            # authenticate only if the user is a superuser
            # or if the site id matches the current site id
            if (($user->sites->find($site->id) or
                 $user->roles->find({ role => 'root' })) and $user->active) {
                if ($c->authenticate({ username => $username,
                                       password => $password })) {
                    log_debug { "User $username successfully authenticated" };
                    $c->session(i_am_human => 1);
                    $c->flash(status_msg => $c->loc("You are logged in now!"));
                    return 1;
                }
            }
            log_info { "User $username not authorized" };
        }
        else {
            log_info { "Unknown user $username" };
        }
        $c->flash(error_msg => $c->loc("Wrong username or password"));
    }
    return 0;
}

sub check_login :Private {
    my ($self, $c) = @_;
    unless ($self->try_to_authenticate($c)) {
        $c->stash(template => 'user/login.tt',
                  nav => 'login',
                  page_title => $c->loc('Login'));
        $c->res->status(403) unless $c->req->uri->path eq '/login';
        $c->detach();
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
    $c->stash(template => 'user/human.tt',
              page_title => $c->loc('Please prove you are a human'));
    
    $c->res->status(403) unless $c->req->uri->path eq '/human';
    $c->detach();
}


1;
