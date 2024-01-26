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
    $c->response->redirect($c->uri_for_action('/bookcovers/edit', $bc->bookcover_id));
}


sub edit :Chained('bookcovers') :PathPart('edit') :Args(1) {
    my ($self, $c, $id) = @_;
    if ($id =~ m/\A\d+\z/a) {
        if (my $bc = $c->stash->{site}->bookcovers->find({ bookcover_id => $id })) {
            my $can_view = 0;
            if ($bc->session_id and $c->sessionid and $c->sessionid eq $bc->session_id) {
                log_debug { "Matched because of session id" };
                $can_view = 1;
            }
            elsif ($bc->user_id and $c->user and $c->user->id eq $bc->user_id) {
                log_debug { "Matched because of user id" };
                $can_view = 1;
            }
            else {
                log_info { "Permission denied to see bc $id" };
            }
            if ($can_view) {
                my $params = $c->request->body_params;
                # post request
                if (%$params) {
                    # TODO handle uploads here
                    $bc->update_from_params($params);
                    if ($params->{compile}) {
                        # need to create a job
                    }
                }
                $c->stash(bookcover => $bc);
                return;
            }
        }
    }
    return $c->detach('/not_found');        
}


__PACKAGE__->meta->make_immutable;

1;
