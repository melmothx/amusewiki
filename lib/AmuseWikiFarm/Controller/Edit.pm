package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use DateTime;
use Text::Wrapper;
use Email::Valid;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse qw/clean_username/;

=head1 NAME

AmuseWikiFarm::Controller::Edit - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 root

Deny access to non human and to human depending on the site type.

=head2 newtext

Path: /new

The main route to create a new text from scratch

=cut

sub root :Chained('/site') :PathPart('action') :CaptureArgs(1) {
    my ($self, $c, $f_class) = @_;

    my $site = $c->stash->{site};
    # librarians can always edit
    if (!$c->user_exists) {
        if ($site->human_can_edit) {
            # but prove it
            if (!$c->session->{i_am_human}) {
                $c->response->redirect($c->uri_for('/human',
                                                   { goto => $c->req->path }));
                $c->detach();
                return;
            }
        }
        else {
            $c->response->redirect($c->uri_for('/login',
                                               { goto => $c->req->path }));
            $c->detach();
            return;
        }
    }

    # validate
    if ($f_class eq 'text' or $f_class eq 'special') {
        $c->stash(f_class => $f_class);
    }
    else {
        $c->detach('/not_found');
        return;
    }

    # but only users can edit special pages
    if ($f_class eq 'special') {
        unless ($c->user_exists) {
            $c->response->redirect($c->uri_for('/login',
                                              { goto => $c->req->path }));
            $c->detach();
        }
    }
}

sub newtext :Chained('root') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    $c->stash(
              nav => 'add-to-library',
              page_title => $c->loc('Add to library'),
             );

    my $site    = $c->stash->{site};
    my $f_class = $c->stash->{f_class} or die;
    # if there was a posting, process it

    if ($c->request->params->{go}) {

        # create a working copy of the params
        my $params = { %{$c->request->params} };

        if (my $fixed_cats = $site->list_fixed_categories) {
            my @out;
            foreach my $cat (@$fixed_cats) {
                # see newtext.tt
                my $param_name = 'fixed_cat_' . $cat;
                if (delete $params->{$param_name}) {
                    # already validated, because we do it the other way
                    push @out, $cat;
                }
            }
            if (@out) {
                $params->{cat} = join(' ', @out);
            }
        }

        # this call is going to add uri to $params, if not present
        my ($revision, $error) = $site->create_new_text($params, $f_class);
        if ($revision) {
            # set the session id
            $revision->session_id($c->sessionid);
            $revision->update;
            $c->flash(status_msg => $c->loc("Created new text"));

            my $uri = $revision->title->uri;
            my $id  = $revision->id;
            my $location = $c->uri_for_action('/edit/edit', [$f_class, $uri, $id]);
            $c->response->redirect($location);
        }
        else {
            $c->stash(processed_params => $params);
            $c->flash(error_msg => $c->loc($error));
        }
    }
}

sub text :Chained('root') :PathPart('edit') :CaptureArgs(1) {
    my ($self, $c, $uri) = @_;
    my $f_class = $c->stash->{f_class} or die;
    # this self validate the f_class
    my $text = $c->stash->{site}->titles->find({
                                                uri => $uri,
                                                f_class => $f_class,
                                               });

    # but only users can edit special pages
    if ($f_class eq 'special') {
        unless ($c->user_exists) {
            $c->response->redirect($c->uri_for('/login',
                                               { goto => $c->req->path }));
            $c->detach();
        }
    }

    if ($text) {
        $c->stash(
                  text_to_edit => $text,
                  page_title => $c->loc('Editing') . ' ' . $text->uri,
                 );
    }
    else {
        my $newuri = $c->uri_for_action('/edit/newtext', [$c->stash->{f_class}]);
        $c->flash(error_msg => $c->loc('This text does not exist'));
        $c->response->redirect($newuri);
        $c->detach();
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
    # show  not published revision which can be merged, i.e., they are not
    # old abandoned and not cleaned up revisions.
    my @revs = grep { $_->can_be_merged } $text->revisions->not_published;

    log_debug { "Got revisions: " . scalar(@revs) };
    if ($text->can_spawn_revision) {
        my $revision;
        if (!@revs || $c->request->params->{create}) {
            $revision = $text->new_revision;
            log_debug { "Creating a new revision" . $revision->id };
        }
        elsif (@revs == 1 and
               !$revs[0]->has_local_modifications and
               !$revs[0]->editing_ongoing) {
            $revision = $revs[0];
            log_debug { "Reusing stale revision " . $revision->id };
        }
        if ($revision) {
            $revision->update({ session_id => $c->sessionid });
            my $location = $c->uri_for_action('/edit/edit', [
                                                             $revision->f_class,
                                                             $uri,
                                                             $revision->id
                                                            ]);
            log_debug { "Redirecting to $location" };
            $c->response->redirect($location);
            $c->detach();
            return;
        }
    }
    log_debug { "We can't decide which revisions to pick!" };
    $c->stash(revisions => \@revs) if @revs;
}

=head2 edit

Path /edit/<my-text>/<id>

This path identifies a revision without ambiguity, and it's here where
the real editing happens.

This also intercepts the embedded images, so they should be handled
here.

=cut

sub get_revision :Chained('text') :PathPart('') :CaptureArgs(1) {
    my ($self, $c, $revision_id) = @_;

    unless ($revision_id =~ m/^[0-9]+$/s) {
        $c->detach(attachments => [$revision_id]);
    }

    my $text = delete $c->stash->{text_to_edit};
    # if we're here and $text was not passed, something is wrong, so we die
    if (my $revision = $text->revisions->find($revision_id)) {
        my @args = ($revision->f_class,
                    $revision->title->uri,
                    $revision->id);
        $c->stash(
                  revision => $revision,
                  editing_uri => $c->uri_for_action('/edit/edit', [@args]),
                  diffing_uri => $c->uri_for_action('/edit/diff', [@args]),
                 );
    }
    else {
        $c->detach('/not_found');
        return;
    }
}

sub edit :Chained('get_revision') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->body_params;
    my $revision = $c->stash->{revision};
    # while editing, prevent multiple session to write stuff
    if ($revision->editing_ongoing and
        $revision->session_id      and
        $revision->session_id ne $c->sessionid) {
        log_debug { $revision->session_id . ' ne ' . $c->sessionid };
        $c->stash->{editing_warnings} =
          $c->loc("This revision is being edited by someone else!");
        $c->stash(locked_editing => 1);
    }
    elsif ($revision->published) {
        $c->stash->{editing_warnings} =
          $c->loc("This revision is already published, ignoring changes");
        $c->stash(locked_editing => 1);
    }
    # on submit, do the editing. Please note that we don't care about
    # the params. We save the body and pass that as preview. So if the
    # user closes the browser, when it has a chance to pick it back.
    elsif ($params->{preview} || $params->{commit} || $params->{upload}) {

        # set the session id
        $revision->session_id($c->sessionid);
        $revision->update;

        log_debug { "Handling the thing" };
        if ($params->{body}) {
            if (my $error = $revision->edit($params)) {
                my $errmsg;
                if (ref($error) and ref($error) eq 'HASH') {
                    $errmsg = $c->loc("Footnotes mismatch: found [_1] footnotes ([_2]) and found [_3] footnote references in the body ([_4]), ignoring changes",
                                      $error->{footnotes},
                                      $error->{footnotes_found},
                                      $error->{references},
                                      $error->{references_found});
                }
                else {
                    $errmsg = $c->loc($error);
                }
                $c->flash(error_msg => $errmsg);
                return;
            }
        }

        # handle the uploads, if any
        foreach my $upload ($c->request->upload('attachment')) {

            log_debug { $upload->tempname . ' => '. $upload->size  };
            if (-f $upload->tempname) {
                log_debug { $upload->tempname . ' exists' };
            }
            else {
                log_error { $upload->tempname . ' does not exist' };
            }
            if (my $error = $revision->add_attachment($upload->tempname)) {
                $c->flash(error_msg => $c->loc(@$error));
            }
            else {
                $c->flash(status_msg => $c->loc("File uploaded!"));
            }
        }

        # if it's a commit, close the editing.
        if ($params->{commit}) {

            # validate the body, it should at least contain a #title
            if ($params->{body} and
                (index($params->{body}, '#title ') >= 0)) {

                # append the message to the existing one
                my $rev_message = $params->{message} || '<no message>';
                my $wrapper = Text::Wrapper->new(columns => 72);
                my $message = $revision->message || '';
                $message .= "\n\n * " . DateTime->now->datetime . "\n" .
                  $wrapper->wrap($rev_message) . "\n";

                # possibly fake, we don't care
                my $reported_username = $params->{username} || 'anonymous';
                $message .= "\n-- \n" . $reported_username . "\n\n";
                $message =~ s/[\r\0]//gs;
                my $username = clean_username($reported_username);
                if ($c->user_exists) {
                    $username = clean_username($c->user->get("username"));
                }
                elsif ($reported_username ne 'anonymous') {
                    # add a prefix, so we know it's not a valid username
                    $username .= ".anon";
                }
                $revision->commit_version($message, $username);
                # assert to have a fresh copy
                $revision->discard_changes;

                my $mail_to =   $c->stash->{site}->mail_notify;
                my $mail_from = $c->stash->{site}->mail_from;
                if ($mail_to && $mail_from) {
                    my $subject = $revision->title->uri;
                    my %mail = (
                                to => $mail_to,
                                from => $mail_from,
                                subject => $revision->title->uri,
                                template => 'commit.tt',
                               );
                    log_info { "Sending mail from $mail_from to $mail_to" };
                    if (my $cc = Email::Valid->address($params->{email})) {
                        $mail{cc} = $cc;
                        log_info { "Adding CC: $cc" };
                    }
                    elsif (my $mail = $params->{email}) {
                        log_warn { "Invalid mail $mail provided, ignoring" };
                    }
                    $c->stash(email => \%mail);
                    $c->forward($c->view('Email::Template'));
                    if (scalar(@{ $c->error })) {
                        $c->flash(error_msg => $c->loc('Error sending mail!'));
                    }
                }
                $c->flash(status_msg => $c->loc("Changes committed, thanks! They are now waiting to be published"));
                if ($c->user_exists || $c->stash->{site}->human_can_publish ) {
                    $c->response->redirect($c->uri_for_action('/publish/pending'));
                }
                else {
                    $c->response->redirect($c->uri_for('/'));
                }
                return;
            }
            else {
                $c->stash->{editing_warnings} =
                  $c->loc("Missing #title header in the text!");
            }
        }
    }
}

sub attachments :Private {
    my ($self, $c, $path) = @_;
    log_debug { "Handling attachment: $path" };
    # first, see if we have something global
    if (my $attach = $c->stash->{site}->attachments->by_uri($path)) {
        log_debug { "Found attachment $path" };
        $c->stash(serve_static_file => $attach->f_full_path_name);
        $c->detach($c->view('StaticFile'));
    }
    else {
        $c->detach('/not_found');
    }
}

=head2 diff

Path: /action/edit/<my-text>/<rev-id>/diff

=cut

sub diff :Chained('get_revision') :PathPart('diff') :Args(0) {
    my ($self, $c) = @_;
    $c->stash->{page_title} =
      $c->loc('Changes for [_1]', $c->stash->{revision}->title->uri);
}


=Head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
