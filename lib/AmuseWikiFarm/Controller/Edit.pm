package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use DateTime;

=head1 NAME

AmuseWikiFarm::Controller::Edit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

TODO: lock a text while someone is editing.

=head1 METHODS

=head2 auto

Deny access to non human. Also fine grain control needed (TODO)

=cut

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->session->{i_am_human}) {
        return 1;
    }
    else {
        $c->session(redirect_after_login => $c->request->path);
        $c->response->redirect($c->uri_for('/human'));
        return 0;
    }
}

=head2 /new

Theis 

=cut

sub root :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(editor => $c->model('Edit'));
}

sub newtext :Chained('root') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # if there was a posting, process it
    if ($c->request->params->{go}) {
        my $model = $c->stash->{editor};

        # create a working copy of the params
        my $params = { %{$c->request->params} };

        # this call is going to add uri to $params, if not present
        my $revision = $model->create_new($params);
        if ($revision) {
            $c->log->debug("All ok, found " . $revision->id);
            $c->flash(status_msg => $c->loc("Created new text"));

            my $uri = $revision->title->uri;
            my $id  = $revision->id;
            my $location = $c->uri_for_action('/edit/edit', [$uri, $id]);
            $c->response->redirect($location);
        }
        else {
            $c->stash(processed_params => $params);
            $c->flash(error_msg => $c->loc($model->error));
            if (my $existing = $model->redirect) {
                $c->flash(status_msg => $existing);
            }
        }
    }
}

sub text :Chained('root') :PathPart('edit') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    my $text = $c->stash->{site}->titles->find({ uri => $uri });
    if ($text) {
        $c->stash->{text_to_edit} = $text;
    }
    else {
        $c->log->debug('text does not exist...');
        $c->detach('/not_found');
    }
}

=head2 revs

Path: /edit/my-text

We end here when a revision is not specified. If there are no existing
revisions, create one and redirect to that one.

If there are one or more, list them and create a button to create a
fresh one forking from the existing one.

=cut

sub revs :Chained('text') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $text = $c->stash->{text_to_edit};
    my $uri  = $text->uri;
    # TODO filter by user
    my @revs = $text->revisions->pending;

    # no existing revision or explicit request by posting: create new
    if (!@revs || $c->request->params->{create}) {
        $c->log->debug("Creating a new revision");
        my $model = $c->stash->{editor};
        my $revision = $model->new_revision($text);
        # on creation, set the session id
        $revision->session_id($c->sessionid);
        $revision->update;
        my $location = $c->uri_for_action('/edit/edit', [ $uri,
                                                         $revision->id ]);
        $c->response->redirect($location);
        $c->detach();
        return;
    }

    # we can't decide ourself, so we list the revs
    my @uris;
    foreach my $rev (@revs) {
        push @uris, {
                     uri => $c->uri_for_action('/edit/edit', [ $uri, $rev->id ]),
                     created => $rev->updated->clone,
                     # TODO add the user
                     user => 0,
                    };
    }
    $c->stash(revisions => \@uris);
}

=head2 edit

Path /edit/<my-text>/<id>

This path identifies a revision without ambiguity, and it's here where
the real editing happens.

This also intercepts the embedded images, so they should be handled
here.

=cut

sub edit :Chained('text') :PathPart('') :Args(1) {
    my ($self, $c, $revision_id) = @_;
    # avoid stash cluttering
    unless ($revision_id =~ m/^[0-9]+$/s) {
        $c->detach(attachments => [$revision_id]);
    }

    my $text = delete $c->stash->{text_to_edit};
    # if we're here and $text was not passed, something is wrong, so we die
    my $revision = $text->revisions->find($revision_id);
    unless ($revision) {
        $c->detach('/not_found');
        return;
    }

    my $params = $c->request->params;

    # while editing, prevent multiple session to write stuff
    if ($revision->editing_ongoing and
        $revision->session_id ne $c->sessionid) {
        $c->stash->{editing_warnings} =
          $c->loc("This revision is being edited by someone else!");
    }
    # on submit, do the editing. Please note that we don't care about
    # the params. We save the body and pass that as preview. So if the
    # user closes the browser, when it has a chance to pick it back.
    elsif ($params->{preview} || $params->{commit} || $params->{upload}) {

        # set the session id
        $revision->session_id($c->sessionid);
        # See Result::Revision for the supported status
        $revision->status('editing');
        $revision->updated(DateTime->now);
        $revision->update;

        $c->log->debug("Handling the thing");
        if (exists $params->{body}) {
            $revision->edit($params);
        }

        # handle the uploads, if any
        foreach my $upload ($c->request->upload('attachment')) {

            $c->log->debug($upload->tempname . ' => '. $upload->size );
            $c->log->debug("Exists!") if -f $upload->tempname;

            if (my $error = $revision->add_attachment($upload->tempname)) {
                $c->flash(error_msg => $c->loc($error));
            }
            else {
                $c->flash(status_msg => $c->loc("File uploaded!"));
            }
        }

        # if it's a commit, close the editing.
        if ($params->{commit}) {
            $c->flash(status_msg => "Changes committed, thanks!");
            $revision->status('pending');
            $revision->update;
            $c->response->redirect($c->uri_for_action('/admin/pending'));
            return;
        }
    }

    $c->stash(revision => $revision);
}

sub attachments :Private {
    my ($self, $c, $path) = @_;
    $c->log->debug("Handling attachment: $path");
    # first, see if we have something global
    if (my $attach = $c->stash->{site}->attachments->by_uri($path)) {
        $c->log->debug("Found attachment $path");
        $c->serve_static_file($attach->f_full_path_name);
    }
    else {
        $c->detach('/not_found');
    }
}


=Head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
