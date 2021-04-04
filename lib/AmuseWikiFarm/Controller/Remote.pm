package AmuseWikiFarm::Controller::Remote;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Utils::Amuse qw/clean_username/;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Remote - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub root :Chained('/site_user_required') :PathPart('remote') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub create :Chained('root') :PathPart('create') :Args {
    my ($self, $c, $f_class) = @_;
    die "Shouldn't happen" unless $c->user_exists;
    $f_class ||= 'library';
    my %params = %{$c->request->body_params};
    foreach my $k (keys %params) {
        delete $params{$k} if $k =~ m/^__/;
    }
    my %response;

    my %classes = (
                   library => 'text',
                   special => 'special',
                  );
    if ($classes{$f_class} && $params{title} && $params{textbody}) {
        my $site = $c->stash->{site};
        my ($revision, $error) = $site->create_new_text(\%params, $classes{$f_class});
        my $user = $c->user->get("username");
        if ($revision) {
            $response{attachments} = $self->_add_files_to_revision($c, $revision);
            $revision->commit_version("Upload from /remote/create",
                                      clean_username($user));
            $revision->discard_changes;
            my $job = $site->jobs->publish_add($revision);
            $response{url} = $c->uri_for($revision->title->full_uri)->as_string;
            $response{job} = $c->uri_for_action('/tasks/display',  [$job->id])->as_string;
        }
        else {
            $response{error} = $error;
        }
    }
    elsif (!$classes{$f_class}) {
        $response{error} = "Invalid entry type: it should be library or special";
    }
    else {
        $response{error} = "Missing mandatory title and textbody parameters";
    }
    $c->stash(json => \%response);
    $c->logout;
    $c->detach($c->view('JSON'));
}

sub edit :Chained('root') :PathPart('edit') :Args(2) {
    my ($self, $c, $type, $uri) = @_;
    die "Shouldn't happen" unless $c->user_exists;
    my %params = %{$c->request->body_params};
    foreach my $k (keys %params) {
        delete $params{$k} if $k =~ m/^__/;
    }
    my %response;
    my %classes = (
                   library => 'text',
                   special => 'special',
                  );
    my $site = $c->stash->{site};
    if ($params{body} && $params{message}) {
        if (my $f_class = $classes{$type}) {
            if (my $title = $site->titles->find({
                                                 f_class => $f_class,
                                                 uri => $uri,
                                                })) {
                if ($title->can_spawn_revision) {
                    log_info { "Creating new revision from API" };
                    my $revision = $title->new_revision;
                    my $commit = delete $params{message};
                    my $error;
                    my $ok;
                    eval {
                        $error = $revision->edit(\%params);
                        $response{attachments} = $self->_add_files_to_revision($c, $revision);
                        unless ($error) {
                            $revision->commit_version($commit, clean_username($c->user->get("username")));
                            my $job = $site->jobs->publish_add($revision, $c->user->get("username"));
                            $response{url} = $c->uri_for($revision->title->full_uri)->as_string;
                            $response{job} = $c->uri_for_action('/tasks/display',  [$job->id])->as_string;
                        }
                    };
                    if (my $err = $@ || $error) {
                        $response{error} = $err;
                    }
                }
                else {
                    $response{error} = "This text cannot be edited";
                }
            }
            else {
                $response{error} = "This text does not exist";
            }
        }
        else {
            $response{error} = "Invalid text type. It should be library or special";
        }
    }
    else {
        $response{error} = "Missing mandatory parameters body and message";
    }
    $c->stash(json => \%response);
    $c->logout;
    $c->detach($c->view('JSON'));
}

=comment

curl -F __auth_user=$username \
       -F __auth_pass=$password \
       -F title=Test \
       -F textbody='Hello <em>hello</em>' \
       -F 'attachment=@prova.png' \
       https://staging.amusewiki.org/remote/create

=cut

sub _add_files_to_revision {
    my ($self, $c, $revision) = @_;
    die "Wrong usage" unless $c && $revision;
    my (@errors, @uris);
    foreach my $upload ($c->request->upload('attachment')) {
        my $mime_type = AmuseWikiFarm::Utils::Amuse::mimetype($upload->tempname);
        if ($c->stash->{site}->allowed_binary_uploads(restricted => !$c->user_exists)->{$mime_type}) {
            my $res = $revision->embed_attachment($upload->tempname);
            if ($res->{uris} and ref($res->{uris}) eq 'ARRAY') {
                push @uris, @{$res->{uris}};
            }
            else {
                push @errors, "Failure to add attachment " . $upload->filename;
            }
        }
        else {
            push @errors, "Unsupported type $mime_type for "  . $upload->filename;
        }
    }
    return {
            uris => \@uris,
            errors => @errors ? \@errors : undef,
           };
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
