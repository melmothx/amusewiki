package AmuseWikiFarm::Controller::BookBuilder;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::BookBuilder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 auto

Deny access to not-human

=cut


sub auto :Private {
    my ($self, $c) = @_;
    $c->stash(nav => 'bookbuilder');
    if ($c->session->{i_am_human}) {
        return 1;
    }
    else {
        my $uri = $c->uri_for($c->action, $c->req->captures,
                              @{ $c->req->args },
                              $c->req->params);
        $c->session(redirect_after_login => $uri);

        $c->response->redirect($c->uri_for('/human'));
        return 0;
    }
}



=head2 index

=cut

sub root :Chained('/') :PathPart('bookbuilder') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # this is the root method. Initialize the session with the list;
    my $bblist = $c->session->{bblist} ||= [];

    # initialize the BookBuilder object
    my $bb = $c->model('BookBuilder');
    $bb->textlist($bblist);

    # set the current page count
    my $bb_page_count = 0;
    foreach my $t (@{$bb->texts}) {
        my $title = $c->stash->{site}->titles->by_uri($t);
        next unless $title;
        $bb_page_count += $title->pages_estimated;
    }
    $c->stash(bb_page_count => $bb_page_count);
    $c->stash(bb => $bb);
}

sub index :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $bb = $c->stash->{bb};
    my @texts = @{ $bb->texts };

    my %params = %{ $c->request->params };

    if (@texts and $params{build} and 
        $params{collectionname} and $params{collectionname} =~ m/\w/) {
        $c->log->debug("Putting the job in the queue now");

        my $bb = $c->stash->{bb};
        my $site_id = $c->stash->{site}->id;

        # prepare the job hash
        my $data = {
                    text_list  => [ @texts ],
                    title      => $params{collectionname},
                    template_options => $bb->validate_options({ %params }),
                    imposer_options  => $bb->validate_imposer_options({ %params }),
                   };

        if (my $job = $c->stash->{site}->jobs->bookbuilder_add($data)) {
            # flush the toilet
            $bb->delete_all;
            $c->forward('save_session');

            # and redirect to the status page
            $c->res->redirect($c->uri_for_action('/tasks/display', [$job->id]));
        }
        # if we get this, the user cheated and doesn't deserve an explanation
        else {
            $c->flash->{error_msg} = $c->loc("Couldn't build that");
        }
    }
}

sub edit :Chained('root') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    if (my $index = $c->request->params->{textindex}) {
        $c->log->debug("Operating on $index");
        if ($c->request->params->{moveup}) {
            $c->stash->{bb}->move_up($index);
        }
        elsif ($c->request->params->{movedw}) {
            $c->stash->{bb}->move_down($index);
        }
        elsif ($c->request->params->{delete}) {
            $c->stash->{bb}->delete_text($index);
        }
    }
    $c->forward('save_session');
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub clear :Chained('root') :PathPart('clear') :Args(0) {
    my ($self, $c) = @_;
    if ($c->request->params->{clear}) {
        $c->stash->{bb}->delete_all;
        $c->forward('save_session');
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub add :Chained('root') :PathPart('add') :Args(0) {
    my ( $self, $c ) = @_;
    if (my $text = $c->request->params->{text}) {

        my $bb   = $c->stash->{bb};
        my $site = $c->stash->{site};

        # do we have the text in the db?
        my $to_add = $site->titles->by_uri($text);
        unless ($to_add) {
            $c->log->warn("Tried to added $text but not found");
            $c->flash->{error_msg} = $c->loc("Couldn't add the text");
            $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
            return;
        }

        # is exceeding the limit?
        my $current_state = $c->stash->{bb_page_count};
        $c->log->debug("Current state is $current_state");

        if (($current_state + $to_add->pages_estimated) > $site->bb_page_limit) {
            $c->flash->{error_msg} = $c->loc("Quota exceeded, too many pages");
            $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
            return;
        }

        if ($bb->add_text($text)) {
            $c->forward('save_session');
            $c->flash->{status_msg} = $c->loc('Text added');
            my $referrer = $c->uri_for_action('/library/text' => $text);
            $c->flash(referrer => $referrer);
        }
        else {
            $c->flash->{error_msg} = $c->loc("Couldn't add the text");
        }
    }
    else {
        $c->flash->{error_msg} = $c->loc("No text provided!");
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub save_session :Private {
    my ( $self, $c ) = @_;
    $c->log->debug('Saving books in the session');
    $c->session->{bblist} = $c->stash->{bb}->texts;
}

=encoding utf8

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
