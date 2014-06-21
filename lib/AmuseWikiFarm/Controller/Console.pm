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
        $c->stash(nav => 'console');
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

sub unpublished_list :Chained('root') :PathPart('unpublished') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my @list = $c->stash->{site}->titles->unpublished;
    $c->stash(page_title => $c->loc('Unpublished texts'));
    if (@list) {
        $c->stash(text_list => \@list)
    }
}

sub unpublished :Chained('unpublished_list') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    # empty to close the chain
}

=head2 purge

Erase the text from the file system and the database. The text must be
already marked as deleted as a safety measure.

=cut

sub purge :Chained('unpublished_list') :PathPart('purge') :Args(0) {
    my ($self, $c) = @_;
    die "This shouldn't happen" unless $c->user_exists;
    if (my $target = $c->request->params->{purge}) {
        # validated
        my $found;
        foreach my $r (@{ $c->stash->{text_list} }) {
            if ($r->id eq $target and $r->deleted) {
                $found = 1;
                last;
            }
        }
        if ($found) {
            my $payload = {
                           id => $target,
                           username  => $c->user->get('username'),
                          };
            my $job = $c->stash->{site}->jobs->purge_add($payload);
            $c->res->redirect($c->uri_for_action('/tasks/display',
                                                 [$job->id]));
            return;
        }
    }
    $c->flash(error_msg => "Bad purge request! Please report this incident");
    $c->response->redirect($c->uri_for_action('/console/unpublished'));
}

=head2 alias

List the exiting redirections and stash the resultset as C<aliases>.

=cut

sub alias :Chained('root') :PathPart('alias') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $rs = $c->stash->{site}->redirections->search({},
                                                     {
                                                      order_by => [qw/type
                                                                      uri/],
                                                     });
    $c->stash(aliases => $rs);
}

=head2 alias_list

Display the aliases

=cut

sub alias_display :Chained('alias') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    $c->stash(
              page_title => $c->loc('Redirections'),
              redirections => [ $c->stash->{aliases}->all ],
              author_list  => [ $c->stash->{site}->my_authors ],
              topic_list   => [ $c->stash->{site}->my_topics  ],
             );
}

sub alias_delete :Chained('alias') :PathPart('delete') :Args(0) {
    my ($self, $c) = @_;
    if (my $id = $c->request->params->{delete}) {
        if (my $alias = $c->stash->{aliases}->find($id)) {
            $c->flash(status_msg => "Deletion for $id set");
            my $job = $c->stash->{site}->jobs->alias_delete_add({ id => $id });
            $c->res->redirect($c->uri_for_action('/tasks/display',
                                                 [$job->id]));
            return;
        }
    }
    $c->flash(error_msg => "No such alias");
    $c->response->redirect($c->uri_for_action('/console/alias_display'));
}

sub alias_create :Chained('alias') :PathPart('create') :Args(0) {
    my ($self, $c) = @_;
    my $params = $c->request->params;
    if (!$params->{src}) {
        $c->flash(error_msg => $c->loc("Missing alias"));
    }
    elsif (!$params->{dest}) {
        $c->flash(error_msg => $c->loc("Missing redirection"));
    }
    elsif ($params->{dest} eq $params->{src}) {
        $c->flash(error_msg => $c->loc("Alias can't be the same of redirection"));
    }
    elsif (($params->{type} eq 'author' or $params->{type} eq 'topic') and
        $params->{src} and $params->{dest} and
        $params->{src} ne $params->{dest}) {
        my $payload = {
                       src => $params->{src},
                       dest => $params->{dest},
                       type => $params->{type}
                      };
        my $job = $c->stash->{site}->jobs->alias_create_add($payload);
        $c->res->redirect($c->uri_for_action('/tasks/display',
                                             [$job->id]));
        return;
    }
    else {
        $c->flash(error_msg => $c->loc("Bad request"));
    }
    $c->response->redirect($c->uri_for_action('/console/alias_display'));
}


=head1 AUTHOR

Marco,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
