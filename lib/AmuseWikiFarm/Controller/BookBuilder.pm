package AmuseWikiFarm::Controller::BookBuilder;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Text::Amuse::Compile::FileName;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::BookBuilder - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 root

Deny access to not-human

=cut

=head2 index

=cut

sub root :Chained('/site') :PathPart('bookbuilder') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    # check if human
    if ($c->sessionid && $c->session->{i_am_human}) {
        $c->stash(nav => 'bookbuilder');
        $c->stash(page_title => $c->loc('Bookbuilder'));
    }
    else {
        $c->response->redirect($c->uri_for('/human', { goto => $c->req->path }));
        $c->detach();
        return;
    }

    # initialize the BookBuilder object. It will pick up the session
    my $bb = $c->model('BookBuilder');
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
                log_debug { "Adding file: " . $upload->tempname . ' => '. $upload->size  };
                $bb->add_file($upload->tempname);
            }
        }
        $self->save_session($c);
    }
    my @texts;
    foreach my $text (@{$bb->texts}) {
        my $filename = Text::Amuse::Compile::FileName->new($text);
        my $data = {
                    name => $filename->name,
                   };
        if (my @fragments = $filename->fragments) {
            $data->{partials} = join('-', @fragments);
        }
        push @texts, $data;
    }
    if (@texts and $params{build}) {
        # put a limit on accepting slow jobs
        unless ($c->model('DB::Job')->can_accept_further_jobs) {
            $c->flash->{error_msg} =
              $c->loc("Sorry, too many jobs pending, please try again later!");
            return;
        }

        log_debug { "Putting the job in the queue now" };

        if (my $job = $c->stash->{site}->jobs->bookbuilder_add($bb->serialize)) {
            $c->res->redirect($c->uri_for_action('/tasks/display', [$job->id]));
        }
        # if we get this, the user cheated and doesn't deserve an explanation
        else {
            $c->flash->{error_msg} = $c->loc("Couldn't build that");
        }
    }
    $c->stash(bb_texts => \@texts);
}

sub edit :Chained('root') :PathPart('edit') :Args(0) {
    my ($self, $c) = @_;
    if (my $index = $c->request->params->{textindex}) {
        log_debug { "Operating on $index" };
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
    # this is basically not needed, because the session's textlist
    # arrayref is modified in place, but better safe than sorry.
    $self->save_session($c);
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub clear :Chained('root') :PathPart('clear') :Args(0) {
    my ($self, $c) = @_;
    if ($c->request->params->{clear}) {
        # override with a shiny new thing
        log_debug { 'Resetting bookbuilder in the session' };
        $c->session->{bookbuilder} = {};
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub add :Chained('root') :PathPart('add') :Args(1) {
    my ( $self, $c, $text ) = @_;
    my $bb   = $c->stash->{bb};
    my $site = $c->stash->{site};
    my $params = $c->request->body_params;
    my $addtext = $text;
    Dlog_debug { "params: $_" } $params;
    if ($params->{partial}) {
        my $selected = $params->{select};
        my @pieces;
        if (defined $selected) {
            if (my $ref = ref($selected)) {
                if ($ref eq 'ARRAY') {
                    @pieces = @$selected;
                }
            }
            else {
                @pieces = ($selected);
            }
        }
        # check
        if (@pieces) {
            $addtext .= ':' . join(',', @pieces);
        }
        my $check = Text::Amuse::Compile::FileName->new($addtext);
        if ($check->name ne $text) {
            log_error { "$addtext is invalid!" };
            $addtext = $text;
        }
    }
    my $referrer = $c->uri_for_action('/library/text', [$text]);
    if ($bb->add_text($addtext)) {
        $self->save_session($c);
        $c->flash->{status_msg} = 'BOOKBUILDER_ADDED';
    }
    elsif (my $err = $bb->error) {
        log_warn { "$err for $text" };
        $c->flash->{error_msg} = $c->loc($bb->error);
    }
    $c->response->redirect($referrer);
    return;
}

sub cover :Chained('root') :Args(0) {
    my ($self, $c) = @_;
    if (my $cover = $c->stash->{bb}->coverfile_path) {
        $c->stash(serve_static_file => $cover);
        $c->detach($c->view('StaticFile'));
    }
    else {
        $c->detach('/not_found');
    }
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
    $c->session->{bookbuilder} = $c->stash->{bb}->serialize;
    Dlog_debug { "bb saved: $_" } $c->stash->{bb}->serialize;
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
