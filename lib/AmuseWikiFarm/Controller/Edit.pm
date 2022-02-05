package AmuseWikiFarm::Controller::Edit;
use strict;
use warnings;
use utf8;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use DateTime;
use Text::Wrapper;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse qw/clean_username clean_html/;
use AmuseWikiFarm::Utils::Paths ();
use Path::Tiny ();

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

sub root :Chained('/site_human_required') :PathPart('action') :CaptureArgs(1) {
    my ($self, $c, $f_class) = @_;

    my $site = $c->stash->{site};

    # validate
    if ($f_class eq 'text' or $f_class eq 'special') {
        $c->stash(f_class => $f_class);
    }
    else {
        $c->detach('/not_found');
        return;
    }

    # but only users can edit special pages
    $self->check_login($c) if ($f_class eq 'special' or !$site->human_can_edit);

    $c->stash(full_page_no_side_columns => 1);
}

sub newtext :Chained('root') :PathPart('new') :Args(0) {
    my ($self, $c) = @_;

    $c->stash(
              nav => 'add-to-library',
              page_title => $c->loc('Add a new text'),
             );

    my $site    = $c->stash->{site};
    my $f_class = $c->stash->{f_class} or die;

    if ($site->category_uri_use_unicode) {
        $c->stash(pop_uri_field_to_the_top => 1);
    }

    # create a working copy of the params
    my $params = { %{$c->request->body_params} };
    Dlog_debug { "In the newtext route $_" } $params;
    # if there was a posting, process it
    if ($params->{go}) {
        my ($upload) = $c->request->upload('texthtmlfile');
        if ($upload) {
            log_debug { $upload->tempname . ' => '. $upload->size  };
            $params->{fileupload} = $upload->tempname;
        }
        else {
            # delete if set as parameter
            delete $params->{fileupload};
        }

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
            $c->flash(error_msg => $c->loc('Not finished yet! Please have a look at the text and then click on "[_1]" to finalize your submission!', $c->loc('Save')));

            my $uri = $revision->title->uri;
            my $id  = $revision->id;
            my $location = $c->uri_for_action('/edit/edit', [$f_class, $uri, $id]);

            # Notify
            my $mail_to =   $c->stash->{site}->mail_notify;
            my $mail_from = $c->stash->{site}->mail_from;
            if ($mail_to && $mail_from) {
                my %mail = (
                            to => $mail_to,
                            from => $mail_from,
                            subject => $revision->title->full_uri,
                            home => $c->uri_for('/'),
                            location => $location,
                           );
                log_info { "Sending mail from $mail_from to $mail_to for new $uri" };
                $c->stash->{site}->send_mail(newtext => \%mail);
            }
            $c->response->redirect($location);
            return;
        }
        else {
            $c->stash(processed_params => $params);

            # this is not a clean solution, but makes sense anyway: if
            # the error concern the URI, we pop the field up.
            if ($error =~  m/URI/) {
                $c->stash(pop_uri_field_to_the_top => 1);
            }
            my $loc_error = $c->loc($error);
            if ($params->{fileupload}) {
                $loc_error .= ' ' . $c->loc("Please upload your file again!");
            }
            $c->flash(error_msg => $loc_error);
        }
    }
    else {
        log_debug { "Nothing to do, rendering form" };
    }
    if ($site->nodes->count) {
        my $nodes = $site->nodes->as_list_with_path($c->stash->{current_locale_code});
        # don't lose the selection
        if ($params->{node_id}) {
            my %selected;
            if (ref($params->{node_id})) {
                $selected{$_} = 1 for @{$params->{node_id}};
            }
            else {
                $selected{$params->{node_id}} = 1;
            }
            Dlog_debug { "Found selected nodes: $_" } \%selected;
            foreach my $n (@$nodes) {
                if ($selected{$n->{value}}) {
                    $n->{checked} = 1;
                }
            }
        }
        Dlog_debug { "Nodes are $_" } $nodes;
        $c->stash(node_checkboxes => $nodes);
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
    $self->check_login($c) if $f_class eq 'special';

    if ($text) {
        log_debug { "Text $uri $f_class found and stashed" };
        $c->stash(
                  text_to_edit => $text,
                  page_title => $c->loc('Editing') . ' ' . $text->uri,
                 );
    }
    else {
        log_debug { "Text $uri $f_class was not found" };
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
        log_debug { "Found the revision " . $revision->id };
        $c->stash(
                  revision => $revision,
                  ajax_editing_uri => $c->uri_for_action('/edit/ajax', [@args]),
                  ajax_delete_uri => $c->uri_for_action('/edit/remove_attachment', [@args]),
                  editing_uri => $c->uri_for_action('/edit/edit', [@args]),
                  diffing_uri => $c->uri_for_action('/edit/diff', [@args]),
                  binary_upload_uri => $c->uri_for_action('/edit/upload', [@args]),
                  upload_listing_uri => $c->uri_for_action('/edit/list_uploads', [@args]),
                  preview_uri => $c->uri_for_action('/edit/preview', [@args]),
                 );
    }
    else {
        $c->detach('/not_found');
        return;
    }
}

sub list_uploads :Chained('get_revision') :PathPart('list-upload') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(json => { uris => $c->stash->{revision}->attached_files });
    $c->detach($c->view('JSON'));
}

sub revision_can_be_edited :Chained('get_revision') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
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
}

sub upload :Chained('revision_can_be_edited') :PathPart('upload') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my @uris;
    my %out;
    if ($c->stash->{locked_editing}) {
        log_error { "Locked editing, no upload possible" };
        $out{error}{message} = $c->loc("Locked editing, no upload possible");
        $out{success} = 0;
    }
    else {
        my $revision = $c->stash->{revision};
        # bounce back the setting
        $out{insert} = $c->request->body_params->{insert} ? 1 : 0;

        if (my ($upload) = $c->request->upload('attachment')) {
            my $file =  $upload->tempname;

            my $mime_type = AmuseWikiFarm::Utils::Amuse::mimetype($file);

            log_info { "Attaching $file $mime_type" };
            my $allowed = $c->stash->{site}->allowed_binary_uploads(restricted => !$c->user_exists);
            unless ($allowed->{$mime_type}) {
                Dlog_info { "$mime_type not allowed $_" } $allowed;
                %out = (success => 0,
                        insert => 0,
                        error => { message => $c->loc("Unsupported file type [_1]", $mime_type) });
                $c->stash(json => \%out);
                $c->detach($c->view('JSON'));
                return;
            }

            my ($w, $h) = AmuseWikiFarm::Utils::Amuse::image_dimensions($file);
            if ($w && $h) {
                if (my $limit = $site->max_image_dimension) {
                    if ($w > $limit or $h > $limit) {
                        %out = (
                                success => 0,
                                insert => 0,
                                error => {
                                          message => $c->loc('Image dimensions [_1] x [_2] exceed limit of [_3] x [_4] pixels',
                                                             $w, $h, $limit, $limit),
                                         },
                               );
                        $c->stash(json => \%out);
                        $c->detach($c->view('JSON'));
                        return;
                    }
                }
            }


            if ($c->request->body_params->{split_pdf}) {
                my $outcome = $revision->add_attachment_as_images($file);
                if ($outcome->{uris}) {
                    push @uris, @{$outcome->{uris}};
                }
            }
            else {
                my $outcome = $revision->add_attachment($file);
                Dlog_debug { "add attachment outcome: $_" } $outcome;
                if ($outcome->{attachment}) {
                    push @uris, $outcome->{attachment};
                }
                elsif ($outcome->{error} and ref($outcome->{error}) eq 'ARRAY') {
                    $out{error}{message} = $c->loc(@{$outcome->{error}});
                }
            }
        }
    }
    if (@uris) {
        $out{success} = 1;
        $out{uris} = \@uris;
    }
    else {
        $out{error}{message} ||= $c->loc("Nothing uploaded");
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub edit_revision :Chained('revision_can_be_edited') :PathPart('') :CaptureArgs(0) {
    my ($self, $c) = @_;
    return if $c->stash->{locked_editing};

    my $params = $c->request->body_params;
    my $revision = $c->stash->{revision};
    if ($params->{preview} || $params->{commit} || $params->{upload}) {

        # set the session id
        $revision->session_id($c->sessionid);
        $revision->update;

        log_debug { "Handling the thing" };
        if ($params->{body}) {
            if (my $error = $revision->edit($params)) {
                my $errmsg;
                if (ref($error) and ref($error) eq 'HASH') {
                    $errmsg = $c->loc("Footnotes mismatch: found [_1] footnotes ([_2]) and found [_3] footnote references in the body ([_4]), ignoring changes.",
                                      $error->{footnotes},
                                      $error->{footnotes_found},
                                      $error->{references},
                                      $error->{references_found});
                    $errmsg .= "\n";
                    $errmsg .= $c->loc("The differences between the list of footnotes and references is shown below.");
                    $c->stash(footnote_error_list_differences => $error->{differences});
                }
                else {
                    $errmsg = $c->loc($error);
                }
                $c->stash(revision_editing_error_msg => $errmsg);
                return;
            }
            else {
                $c->stash(revision_edited_ok => 1);
            }
        }
    }
}

sub edit :Chained('edit_revision') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->body_params;
    my $revision = $c->stash->{revision};
    my $site = $c->stash->{site};
    $c->stash(
              load_highlight => $site->use_js_highlight,
              load_markitup_css => 1,
             );

    {
        my @exts = (qw/png jpg pdf/);
        if ($c->user_exists && $site->allow_binary_uploads) {
            push @exts, $site->allowed_upload_extensions;
        }
        $c->stash(allowed_upload_extensions => join(', ', map { uc($_) } @exts));
    }

    # layout settings
    my %layout_settings = (edit_option_preview_box_height => 0,
                           edit_option_show_filters => 0,
                           edit_option_show_cheatsheet => 0,
                           edit_option_page_left_bs_columns => 0);
    {
        my $setter = $c->user_exists ? $c->user->get_object->discard_changes : $site;
        foreach my $k (keys %layout_settings) {
            $layout_settings{$k} = $setter->$k;
        }
    }
    Dlog_debug { "layout settings: $_" }  \%layout_settings;
    # extremely verbose but hey.
    $layout_settings{edit_option_page_right_bs_columns} = 12 - $layout_settings{edit_option_page_left_bs_columns};
    if ($layout_settings{edit_option_page_right_bs_columns} < 3 or
        $layout_settings{edit_option_page_right_bs_columns} > 10) {
        $layout_settings{edit_option_page_right_bs_columns} = $layout_settings{edit_option_page_left_bs_columns} = 6;
    }
    $c->stash(%layout_settings);

    # on submit, do the editing. Please note that we don't care about
    # the params. We save the body and pass that as preview. So if the
    # user closes the browser, when it has a chance to pick it back.
    return if $c->stash->{locked_editing};

    if ($params->{preview} || $params->{commit} || $params->{upload}) {

        # legacy handling of uploads
      UPLOAD:
        foreach my $upload ($c->request->upload('attachment')) {

            log_debug { $upload->tempname . ' => '. $upload->size . " User exists" . $c->user_exists };
            if (-f $upload->tempname) {
                log_debug { $upload->tempname . ' exists' };
            }
            else {
                log_error { $upload->tempname . ' does not exist' };
                die "Shouldn't happen, " . $upload->tempname . ' does not exist';
            }

            my $mime_type = AmuseWikiFarm::Utils::Amuse::mimetype($upload->tempname);
            my $allowed = $site->allowed_binary_uploads(restricted => !$c->user_exists);
            unless ($allowed->{$mime_type}) {
                $c->flash(error_mgs => $c->loc("Unsupported file type [_1]", $mime_type));
                Dlog_info { "Refusing to upload $mime_type: $_" } $allowed;
                next UPLOAD;
            }
            my $outcome;
            if ($params->{add_attachment_to_body}) {
                $outcome = $revision->embed_attachment($upload->tempname);
            }
            else {
                $outcome = $revision->add_attachment($upload->tempname);
            }
            if (my $error = $outcome->{error}) {
                $c->flash(error_msg => $c->loc(@$error));
            }
            elsif ($outcome->{attachment}) {
                log_info { "Attached $outcome->{attachment}" };
                $c->flash(status_msg => $c->loc("File uploaded!"));
            }
            else {
                Dlog_error { "$_ is not what I expected!" } $outcome;
            }
        }

        if (my $errmsg = $c->stash->{revision_editing_error_msg}) {
            $c->flash(error_msg => $errmsg);
            return;
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
                $message .= "\n\n * " . DateTime->now->datetime . "\n\n" .
                  $wrapper->wrap($rev_message) . "\n";

                # possibly fake, we don't care
                my $reported_username = clean_username($params->{username});
                $message .= "\n-- " . $reported_username . "\n\n";
                $message =~ s/[\r\0]//gs;
                if ($c->user_exists) {
                    $reported_username = clean_username($c->user->get("username"));
                }
                elsif ($reported_username ne 'anonymous') {
                    # add a prefix, so we know it's not a valid username
                    $reported_username .= ".anon";
                }
                $revision->commit_version($message, $reported_username);
                # assert to have a fresh copy
                $revision->discard_changes;

                my $mail_to =   $site->mail_notify;
                my $mail_from = $site->mail_from;
                if ($mail_to && $mail_from) {
                    my $uri = $revision->title->uri;
                    my @url_args = ($revision->f_class, $uri, $revision->id);
                    my @file_urls;
                    if (my $files = $revision->attached_files) {
                        foreach my $file (@$files) {
                            push @file_urls,
                              $c->uri_for_action('/edit/edit', [ $revision->f_class,
                                                                 $uri, $file ]);
                        }
                    }
                    Dlog_debug { "Files are $_ " } \@file_urls;
                    my %mail = (
                                to => $mail_to,
                                from => $mail_from,
                                subject => $revision->title->full_uri,
                                author_title => clean_html($revision->title->author_title),
                                document_uri => $c->uri_for($revision->title->full_uri),
                                cc => $params->{email},
                                revision_is_new => $revision->is_new_text || 0,
                                home => $c->uri_for('/'),
                                resume_url =>  $c->stash->{editing_uri},
                                diff_url   =>  $c->stash->{diffing_uri},
                                preview_url => $c->stash->{preview_uri},
                                pending_url => $c->uri_for_action('/publish/pending'),
                                attachments => \@file_urls,
                                messages => $revision->message,
                               );
                    log_info { "Sending mail from $mail_from to $mail_to" };
                    $site->send_mail(commit => \%mail);
                }
                $c->flash(status_msg => $c->loc("Changes saved, thanks! They are now waiting to be published"));
                if ($c->user_exists || $site->human_can_publish ) {
                    if ($site->express_publishing && $revision->only_one_pending) {
                        log_debug { "Express publishing in effect" };
                        my $job = $site->jobs->publish_add($revision,
                                                           $c->user_exists ? $c->user->get("username") : '');
                        $c->res->redirect($c->uri_for_action('/tasks/display',
                                                             [$job->id],
                                                             { express => 1 }));
                    }
                    else {
                        $c->response->redirect($c->uri_for_action('/publish/pending'));
                    }
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

sub ajax :Chained('edit_revision') :PathPart('ajax') :Args(0) {
    my ($self, $c) = @_;
    my %out;
    if ($c->stash->{revision_edited_ok}) {
        $out{success} = 1;
        $out{body} = $c->stash->{revision}->muse_body;
    }
    elsif ($c->stash->{locked_editing}) {
        $out{error}{message} = $c->stash->{editing_warnings} || "Editing is locked";
    }
    elsif ($c->stash->{revision_editing_error_msg}) {
        $out{error}{message} = $c->stash->{revision_editing_error_msg};
        $out{error}{footnotesdebug} = $c->stash->{footnote_error_list_differences};
    }
    else {
        log_debug { "Nothing to do" };
    }
    Dlog_debug { "Output is $_" } \%out;
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

sub remove_attachment :Chained('revision_can_be_edited') :PathPart('ajax-remove-attachment') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->body_params;
    my $out = {};
    if ($params->{remove}) {
        $out = $c->stash->{revision}->remove_attachment($params->{remove});
    }
    $c->stash(json => $out);
    $c->detach($c->view('JSON'));
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

=head2 preview

Path: /action/edit/<my-text>/<rev-id>/preview

=cut

sub preview :Chained('get_revision') :PathPart('preview') :Args(0) {
    my ($self, $c) = @_;
    log_debug { "Rendering preview" };
}

sub preview_attachment :Chained('get_revision') :PathPart('') Args(1) {
    my ($self, $c, $attach) = @_;
    $c->detach(attachments => [ $attach ]);
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
