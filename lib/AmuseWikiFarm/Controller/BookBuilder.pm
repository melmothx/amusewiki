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

use Data::Dumper;
use AmuseWikiFarm::Archive::BookBuilder;

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->session->{i_am_human}) {
        $c->stash(nav => 'bookbuilder');
        $c->stash(page_title => $c->loc('Bookbuilder'));
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
    my $bb_args = $c->session->{bookbuilder} || {};

    # initialize the BookBuilder object
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(%$bb_args);

    # set the current page count
    my $bb_page_count = 0;
    foreach my $t (@{$bb->texts}) {
        my $title = $c->stash->{site}->titles->text_by_uri($t);
        next unless $title;
        $bb_page_count += $title->pages_estimated;
    }
    $c->stash(bb_page_count => $bb_page_count);
    $c->stash(bb => $bb);
}

sub index :Chained('root') :PathPart('') :Args(0) {
    my ($self, $c) = @_;

    my $bb = $c->stash->{bb};
    my %params = %{ $c->request->body_parameters };
    if ($params{build} || $params{update}) {
        $bb->import_from_params(%params);
        unless ($params{removecover}) {
            foreach my $upload ($c->request->upload('coverimage')) {
                $c->log->debug("Adding file: " . $upload->tempname . ' => '. $upload->size );
                $bb->add_file($upload->tempname);
            }
        }
        $c->forward('save_session');
    }

    my @texts = @{ $bb->texts };

    if (@texts and $params{build}) {
        $c->log->debug("Putting the job in the queue now");
        # fake loop, should be only one. Last one override, anyway.

        if (my $job = $c->stash->{site}->jobs->bookbuilder_add($bb->as_job)) {
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
        # override with a shiny new thing
        $c->stash->{bb} = AmuseWikiFarm::Archive::BookBuilder->new;
        $c->forward('save_session');
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub add :Chained('root') :PathPart('add') :Args(1) {
    my ( $self, $c, $text ) = @_;
        my $bb   = $c->stash->{bb};
        my $site = $c->stash->{site};
        my $referrer = $c->uri_for_action('/library/text', [$text]);

        # do we have the text in the db?
        my $to_add = $site->titles->text_by_uri($text);
        unless ($to_add) {
            $c->log->warn("Tried to added $text but not found");
            $c->flash->{error_msg} = $c->loc("Couldn't add the text");
            $c->response->redirect($referrer);
            return;
        }

        # is exceeding the limit?
        my $current_state = $c->stash->{bb_page_count};
        $c->log->debug("Current state is $current_state");

        if (($current_state + $to_add->pages_estimated) > $site->bb_page_limit) {
            $c->flash->{error_msg} = $c->loc("Quota exceeded, too many pages");
            $c->response->redirect($referrer);
            return;
        }

        if ($bb->add_text($text)) {
            $c->forward('save_session');
            $c->flash->{status_msg} = 'BOOKBUILDER_ADDED';
        }
        else {
            $c->flash->{error_msg} = $c->loc("Couldn't add the text");
        }
        $c->response->redirect($referrer);
        return;
}

sub fonts :Chained('root') :PathPart('fonts') :Args(0) {
    my ($self, $c) = @_;
    my $all_fonts = $c->stash->{bb}->all_fonts;
    my @out;
    foreach my $font (@$all_fonts) {
        my %myfont = %$font;
        my $name = $myfont{name};
        $name =~ s/ /-/g;
        my $path = "/static/images/font-preview/";
        $myfont{thumb} = $c->uri_for($path . $name . '.png');
        $myfont{pdf}   = $c->uri_for($path . $name . '.pdf');
        push @out, \%myfont;
    }
    $c->stash(page_title => $c->loc('Font preview'),
              all_fonts => \@out);
}

sub schemas :Chained('root') :PathPart('schemas') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Imposition schemas'));
}

sub save_session :Private {
    my ( $self, $c ) = @_;
    $c->log->debug('Saving books in the session');
    $c->session->{bookbuilder} = $c->stash->{bb}->constructor_args;
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
