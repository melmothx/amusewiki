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
    my $bc = $c->stash->{site}->bookcovers->create({
                                                    created => DateTime->now(time_zone => 'UTC'),
                                                    session_id => $c->sessionid,
                                                    $c->user_exists ? (user_id => $c->user->id) : (),
                                                   });
    # template selection should happen here, otherwise we need to redo
    # these steps
    $bc->create_working_dir;
    $bc->populate_tokens;
    $c->response->redirect($c->uri_for_action('/bookcovers/edit', [ $bc->bookcover_id ]));
}

sub find :Chained('bookcovers') :PathPart('bc') :CaptureArgs(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A\d+\z/a) {
        my $user = $c->user ? $c->user->get_object : undef;
        if (my $bc = $c->stash->{site}->bookcovers->find({ bookcover_id => $id })) {
            my $can_view = 0;
            if ($bc->session_id and $c->sessionid and $c->sessionid eq $bc->session_id) {
                log_debug { "Matched because of session id" };
                $can_view = 1;
            }
            elsif ($bc->user_id and $user and $user->id eq $bc->user_id) {
                log_debug { "Matched because of user id" };
                $can_view = 1;
            }
            else {
                log_info { "Permission denied to see bc $id" };
            }
            if ($can_view) {
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
    if ($type) {
        if ($type eq 'zip') {
        }
        elsif ($type eq 'pdf') {
        }
    }
}


__PACKAGE__->meta->make_immutable;

1;
