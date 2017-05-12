package AmuseWikiFarm::Controller::BookBuilder;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use Text::Amuse::Compile::FileName;
use AmuseWikiFarm::Log::Contextual;
use URI;
use Try::Tiny;

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

sub root :Chained('/site_human_required') :PathPart('bookbuilder') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(nav => 'bookbuilder',
              page_title => $c->loc('Bookbuilder'));

    # initialize the BookBuilder object. It will pick up the session
    my $bb = $c->model('BookBuilder');
    $c->stash(bb => $bb);
    if ($c->user_exists) {
        if (my $user = $c->user->get_object) {
            $c->stash(user_object => $user);
            my $profiles = $user->bookbuilder_profiles->search(undef);
            my @bbprofiles;
            while (my $profile = $profiles->next) {
                push @bbprofiles, { name => $profile->profile_name,
                                    id => $profile->bookbuilder_profile_id };
            }
            if (@bbprofiles) {
                $c->stash(bb_profiles => \@bbprofiles);
            }
        }
    }
    $bb->refresh_text_list;
    $c->stash(full_page_no_side_columns => 1);
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
            if ($c->user_exists) {
                $job->update({ username => $c->user->get('username') });
            }
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
    $c->stash->{bb}->clear;
    if ($c->request->params->{clear}) {
        $self->save_session($c);
        log_debug { 'Cleared bookbuilder in the session' };
    }
    elsif ($c->request->params->{reset}) {
        log_debug { 'Resetting bookbuilder in the session' };
        $c->session->{bookbuilder} = {};
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub add :Chained('root') :PathPart('add') :Args(1) {
    my ( $self, $c, $text ) = @_;
    my $bb   = $c->stash->{bb};
    my $site = $c->stash->{site};
    my $params = $c->request->params;
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
    log_debug { "Added $addtext" };
    if ($bb->add_text($addtext)) {
        $c->flash->{status_msg} = 'BOOKBUILDER_ADDED';
        $self->save_session($c);
    }
    elsif (my $err = $bb->error) {
        log_warn { "$err for $text" };
        $c->flash->{error_msg} = $c->loc($bb->error);
    }
    else {
        $self->save_session($c);
    }
    $c->response->redirect($referrer);
    return;
}

sub cover :Chained('root') :Args(0) {
    my ($self, $c) = @_;
    if (my $cover = $c->stash->{bb}->coverfile_path) {
        log_debug { "serving $cover" };
        $c->stash(serve_static_file => $cover);
        $c->detach($c->view('StaticFile'));
    }
    else {
        $c->detach('/not_found');
    }
}

sub profile :Chained('root') :Args(1) {
    my ($self, $c, $profile_id) = @_;
    my $redirect = $c->uri_for_action('/bookbuilder/index');
    my $bbprofile_sec = $c->uri_for_action('/bookbuilder/index'). '#bb-profiles';
    if (my $user = $c->stash->{user_object}) {
        log_debug { "User found " . $user->username };
        if ($profile_id =~ m/\A[0-9]+\z/) {
            log_debug { "Profile is valid $profile_id" };
            if (my $profile = $user->bookbuilder_profiles->find($profile_id)) {
                log_info { "Found $profile_id" };
                my $params = $c->request->body_parameters;
                if ($params->{profile_delete}) {
                    log_info { "Deleting $profile_id" };
                    $profile->delete;
                    $c->response->redirect($bbprofile_sec);
                    return;
                }
                if (length($params->{profile_name})) {
                    log_debug { "Renaming profile $profile_id" };
                    $profile->rename_profile($params->{profile_name});
                    $redirect = $bbprofile_sec;
                }
                my $pname = $profile->profile_name;
                if ($params->{profile_update}) {
                    log_debug { "Saving profile $profile_id" };
                    $profile->update_profile_from_bb($c->stash->{bb});
                    $c->flash(status_msg => $c->loc('Saved "[_1]" configuration',
                                                    $pname));
                }
                if ($params->{profile_load}) {
                    my $existing = $c->stash->{bb}->serialize;
                    my $new = $profile->bookbuilder_arguments;
                    $c->session->{bookbuilder} = { %$existing, %$new };
                    $c->flash(status_msg => $c->loc('Loaded "[_1]" configuration',
                                                    $pname));
                }
                $c->response->redirect($redirect);
                return;
            }
        }
    }
    log_debug { "Falling back to 404" };
    $c->detach('/not_found');
}

sub create_profile :Chained('root') :Args(0) :PathPart('create-profile') {
    my ($self, $c, $profile_id) = @_;
    if (my $user = $c->stash->{user_object}) {
        if ($c->request->body_parameters->{create_profile}) {
            try {
                $user->add_bb_profile($c->request->body_parameters->{profile_name},
                                      $c->stash->{bb});
            } catch {
                my $error = $_;
                log_error { "Failed to create profile: $error" };
            };
        }
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index') . '#bb-profiles');
}

sub fonts :Chained('root') :PathPart('fonts') :Args(0) {
    my ($self, $c) = @_;
    my $all_fonts = $c->stash->{bb}->all_fonts;
    my @out;
    foreach my $font (@$all_fonts) {
        my %myfont = (
                      name => $font->name,
                      desc => $font->desc,
                     );
        my $name = $myfont{name};
        $name =~ s/ /-/g;
        my $path = "/static/images/font-preview/";
        my $pdf = $c->path_to(File::Spec->catfile(qw/root static images font-preview/, $name . '.pdf'));
        if (-f $pdf) {
            $myfont{thumb} = $c->uri_for($path . $name . '.png');
            $myfont{pdf}   = $c->uri_for($path . $name . '.pdf');
            push @out, \%myfont;
        }
        else {
            log_error { "Couldn't find $pdf" };
        }
    }
    $c->stash(page_title => $c->loc('Font preview'),
              all_fonts => \@out);
}

sub schemas :Chained('root') :PathPart('schemas') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Imposition schemas'));
}

sub load :Chained('root') :Args(0) {
    my ( $self, $c ) = @_;
    my $ok;
    if (my $token = $c->request->body_parameters->{token}) {
        if (my $bb = $c->stash->{bb}->load_from_token($token . '')) {
            $c->stash(bb => $bb);
            $self->save_session($c);
            $ok = 1;
        }
    }
    unless ($ok) {
        $c->flash->{error_msg} = $c->loc('Unable to load the bookbuilder session');
    }
    $c->response->redirect($c->uri_for_action('/bookbuilder/index'));
}

sub save_session :Private {
    my ( $self, $c ) = @_;
    $c->session->{bookbuilder} = $c->stash->{bb}->serialize;
    Dlog_debug { "bb saved: $_" } $c->session->{bookbuilder};
    # save the bb state in the db
    $c->session->{bookbuilder_token} = $c->stash->{bb}->save_session;
}

=encoding utf8

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
