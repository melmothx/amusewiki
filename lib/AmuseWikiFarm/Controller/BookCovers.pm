package AmuseWikiFarm::Controller::BookCovers;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use DateTime;

sub bookcovers :Chained('/site_human_required') :PathPart('bookcovers') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub create :Chained('bookcovers') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
    # add the user
    my %values = (
                  created => DateTime->now(time_zone => 'UTC'),
                  session_id => $c->sessionid,
                  $c->user_exists ? (user_id => $c->user->id) : (),
                 );
    my $bc = $c->stash->{site}->bookcovers->create_and_initalize(\%values);
    $c->response->redirect($c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]));
}

sub find :Chained('bookcovers') :PathPart('bc') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A\d+\z/a) {
        my $user = $c->user ? $c->user->get_object : undef;
        # if we have a user, do this cross-site
        if ($user) {
            if (my $bc = $user->bookcovers->find($id)) {
                $c->stash(bookcover => $bc);
                return;
            }
        }
        # otherwise search by session, same site
        if (my $bc = $c->stash->{site}->bookcovers->find({ bookcover_id => $id })) {
            if ($bc->session_id and $c->sessionid and $c->sessionid eq $bc->session_id) {
                $c->stash(bookcover => $bc);
                return;
            }
        }
    }
    $c->detach('/not_found');
}

sub edit :Chained('find') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $bc = $c->stash->{bookcover};
    # shouldn't happen.
    return $c->detach('/not_found') unless $bc;
    my $params = $c->request->body_params;
    # post request
    if (%$params) {
        # TODO handle uploads here
        $bc->update_from_params($params);
        if ($params->{build}) {
            my $job = $site->jobs->enqueue(build_bookcover => {
                                                               id => $bc->bookcover_id,
                                                              }, $bc->username);
            $c->res->redirect($c->uri_for_action('/tasks/display',
                                                 [$job->id]));
        }
    }
}

sub download :Chained('find') :PathPart('download') :Args {
    my ($self, $c, $type) = @_;
    if (my $bc = $c->stash->{bookcover}) {
        if ($bc->compiled) {
            if ($type =~ m/\.zip\z/) {
                if (my $path = $bc->zip_path) {
                    $c->stash(serve_static_file => $path);
                    $c->detach($c->view('StaticFile'));
                    return;
                }
            }
            elsif ($type =~ m/\.pdf\z/) {
                if (my $path = $bc->pdf_path) {
                    $c->stash(serve_static_file => $path);
                    $c->detach($c->view('StaticFile'));
                    return;
                }
            }
        }
    }
    return $c->detach('/not_found');
}

sub remove :Chained('find') :PathPart('remove') :Args(0) {
    my ($self, $c, $type) = @_;
    if ($c->request->body_params->{remove}) {
        if (my $bc = $c->stash->{bookcover}) {
            $c->flash(status_msg => $c->loc("Cover removed"));
            $bc->delete;
        }
    }
    if ($c->user_exists) {
        $c->res->redirect($c->uri_for_action('/user/bookcovers'));
    }
    else {
        $c->res->redirect($c->uri_for('/'));
    }
}

sub clone :Chained('find') :PathPart('clone') :Args(0) {
    my ($self, $c) = @_;
    if (my $src = $c->stash->{bookcover}) {
        my %values = $src->get_columns;
        foreach my $f (qw/created session_id user_id bookcover_id/) {
            delete $values{$f};
        }
        $values{created} = DateTime->now(time_zone => 'UTC');
        $values{session_id} = $c->sessionid;
        if ($c->user_exists) {
            $values{user_id} = $c->user->id;
        }
        my $bc = $c->stash->{site}->bookcovers->create_and_initalize(\%values);
        $c->response->redirect($c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]));
    }
}

__PACKAGE__->meta->make_immutable;

1;
