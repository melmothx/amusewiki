package AmuseWikiFarm::Controller::Console;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

AmuseWikiFarm::Controller::Console - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 auto

In this namespace we manage remote gits. So not logged in can't enter
here.

=cut

sub auto :Private {
    my ($self, $c) = @_;
    if ($c->user_exists) {
        return 1;
    }
    else {
        $c->session(redirect_after_login => $c->request->path);
        $c->response->redirect($c->uri_for('/login'));
        return;
    }
}

=head2 root

Empty base method for chaining

=head2 git

Private, retrieve the remote gits

=head2 git_display

Endpoint for git

=head2 git_action

Posting here will trigger the action

=cut

sub root :Chained('/') :PathPart('console') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub git :Chained('root') :PathPart('git') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my @remotes = $c->stash->{site}->remote_gits;
    $c->stash(remotes => \@remotes);
    $c->stash(repo_validation => $c->stash->{site}->remote_gits_hashref);
}

sub git_display :Chained('git') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(page_title => $c->loc('Git console'));
}


sub git_action :Chained('git') :PathPart('action') :Args(0) {
    my ($self, $c) = @_;
    my $remote = $c->request->params->{remote};
    my $action = $c->request->params->{action};
    if ($remote && $action && $c->stash->{repo_validation}->{$remote}->{$action}) {
        my $payload = {
                       remote => $remote,
                       action => $action,
                      };
        my $job = $c->stash->{site}->jobs->git_action_add($payload);

        $c->res->redirect($c->uri_for_action('/tasks/display',
                                             [$job->id]));

    }
    else {
        $c->flash(error_msg => "Bad request! Please report this incident");
        $c->response->redirect($c->uri_for_action('/console/git_display'));
    }
}

=head2 unpublished

List the unpublished titles.

=cut

sub unpublished :Chained('root') :PathPart('unpublished') :Args(0) {
    my ($self, $c) = @_;
    my @list = $c->stash->{site}->titles->unpublished;
    $c->stash(page_title => $c->loc('Unpublished texts'));
    if (@list) {
        $c->stash(text_list => \@list)
    }
}

=head2 purge

Erase the text from the file system and the database. The text must be
already marked as deleted as a safety measure.

=cut

sub purge :Chained('root') :PathPart('purge') :Args(0) {
    my ($self, $c) = @_;
    die "This shouldn't happen" unless $c->user_exists;
    if (my $target = $c->request->params->{purge}) {
        my $payload = {
                       id => $target,
                       username  => $c->user->get('username'),
                      };
        my $job = $c->stash->{site}->jobs->purge_add($payload);
        $c->res->redirect($c->uri_for_action('/tasks/display',
                                             [$job->id]));
    }
    else {
        $c->flash(error_msg => "Bad purge request! Please report this incident");
        $c->response->redirect($c->uri_for_action('/console/unpublished'));
    }
}

=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
