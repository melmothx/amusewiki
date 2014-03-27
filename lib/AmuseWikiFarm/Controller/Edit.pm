package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Edit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

TODO: lock a text while someone is editing.

=head1 METHODS

=cut


=head2 /new

Theis 

=cut

sub root :Chained('/') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(editor => $c->model('Edit'));
}

sub index :Chained('root') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    # if there was a posting, process it
    if ($c->request->params->{go}) {
        my $model = $c->stash->{editor};
        my $revision = $model->create_new($c->request->params);
        if ($revision) {
            $c->log->debug("All ok, found " . $revision->id);
            $c->flash->{status_msg} = $c->loc("Created new text");

            my $uri = $revision->title->uri;
            my $id  = $revision->id;
            my $location = $c->uri_for_action('/edit/edit', [$uri, $id]);
            $c->response->redirect($location);
        }
        else {
            $c->flash->{error_msg} = $c->loc($model->error);
            if (my $existing = $model->redirect) {
                $c->flash->{status_msg} = $existing;
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
    my @revs = $text->revisions->all;

    # no existing revision or explicit request by posting: create new
    if (!@revs || $c->request->params->{create}) {
        $c->log->debug("Creating a new revision");
        my $model = $c->stash->{editor};
        my $revision = $model->new_revision($text);
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
    }

    # TODO manage file uploads
    if ($c->request->params->{preview}) {
        # save a copy and overwrite
    }
    elsif ($c->request->params->{submit}) {
        # TODO release the lock and schedule a job.
        # maybe also cleanup the files.
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
