package AmuseWikiFarm::Controller::Console;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Controller::Console - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 root

In this namespace we manage remote gits. So not logged in can't enter
here.

=head2 git

Private, retrieve the remote gits

=head2 git_display

Endpoint for git

=head2 git_action

Posting here will trigger the action

=cut

sub root :Chained('/site_user_required') :PathPart('console') :CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(full_page_no_side_columns => 1,
              nav => 'console');
}

sub git :Chained('root') :PathPart('git') :CaptureArgs(0) {
    my ($self, $c) = @_;
    unless ($c->stash->{site}->git) {
        $c->flash(error_msg => $c->loc("Git is not enabled on this site"));
        $c->response->redirect($c->uri_for('/'));
        $c->detach();
        return;
    }
    my @remotes = $c->stash->{site}->remote_gits;
    Dlog_debug { "Remotes are $_" } \@remotes;
    my $username = $c->user->get('username');
    die "This shouldn't happen, no username" unless $username;
    my $found_own = 0;
    foreach my $remote (@remotes) {
        if ($remote->{name} eq $username) {
            $remote->{owner} = 1;
            $found_own = 1;
        }
    }
    $c->stash(user_has_own_remote => $found_own,
              remotes => [ grep { $_->{action} && $_->{action} eq 'fetch' } @remotes ],
              repo_validation => $c->stash->{site}->remote_gits_hashref);
}

sub git_display :Chained('git') :PathPart('') :Args(0) {
    my ($self, $c) = @_;
    my $group = getgrgid($));
    $c->stash(page_title => $c->loc('Git console'),
              amw_group_name => $group,
             );
}

sub add_git_remote :Chained('git') :PathPart('add') :Args(0) {
    my ($self, $c) = @_;
    my $name = $c->request->body_params->{name} || '';
    my $url = $c->request->body_params->{url} || '';
    log_debug { "Adding $name => $url" };
    if ($name and $url and $name eq $c->user->get('username')) {
        if ($c->stash->{site}->add_git_remote($name, $url)) {
            $c->flash(status_msg => $c->loc("Remote repository [_1] added", "$name $url"));
        }
        else {
            $c->flash(error_msg => $c->loc("Failed to add remote repository [_1]", "$name $url"));
        }
    }
    $c->res->redirect($c->uri_for_action('/console/git_display'));
}

sub remove_git_remote :Chained('git') :PathPart('remove') :Args(0) {
    my ($self, $c) = @_;
    my $name = $c->request->body_params->{name};
    if ($name and $name eq $c->user->get('username')) {
        if ($c->stash->{site}->remove_git_remote($name)) {
            $c->flash(status_msg => $c->loc("Remote repository [_1] removed", $name));
        }
        else {
            $c->flash(error_msg => $c->loc("Failed to remove Remote repository [_1]", $name));
        }
    }
    $c->res->redirect($c->uri_for_action('/console/git_display'));
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
        my $job = $c->stash->{site}->jobs->git_action_add($payload, $c->user->get('username'));

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
    $c->stash(load_datatables => 1);
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
            my $username = $c->user->get('username');
            my $payload = {
                           id => $target,
                           username  => $username,
                          };
            my $job = $c->stash->{site}->jobs->purge_add($payload, $username);
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
            my $job = $c->stash->{site}->jobs->alias_delete_add({ id => $id }, $c->user->get('username'));
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
        $c->flash(error_msg => $c->loc("Alias can't point to itself"));
    }
    elsif (($params->{type} eq 'author' or $params->{type} eq 'topic') and
        $params->{src} and $params->{dest} and
        $params->{src} ne $params->{dest}) {
        my $payload = {
                       src => $params->{src},
                       dest => $params->{dest},
                       type => $params->{type}
                      };
        my $job = $c->stash->{site}->jobs->alias_create_add($payload, $c->user->get('username'));
        $c->res->redirect($c->uri_for_action('/tasks/display',
                                             [$job->id]));
        return;
    }
    else {
        $c->flash(error_msg => $c->loc("Bad request"));
    }
    $c->response->redirect($c->uri_for_action('/console/alias_display'));
}

sub translations :Chained('root') :PathPart('translations') :Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    if ($site->multilanguage) {
        $c->stash(
                  translations => $site->translations_list,
                  page_title => $c->loc('Internal list of translations'),
                 );
    }
    else {
        $c->detach('/not_found');
    }
}

sub categories :Chained('root') :PathPart('categories') :CaptureArgs(0) {
    my ($self, $c) = @_;
}

sub list_categories :Chained('categories') :PathPart('list') :Args(0) {
    my ($self, $c) = @_;
    my @all = $c->stash->{site}->categories->sorted->all;
    $c->stash(
              page_title => $c->loc('Manage categories'),
              categories => \@all,
              toggler_url => $c->uri_for_action('/console/toggle_category'),
              load_datatables => 1,
             );
}

sub toggle_category :Chained('categories') :PathPart('toggle') :Args(0) {
    my ($self, $c) = @_;
    my %out;
    if (my $id = $c->request->params->{toggle}) {
        if (my $cat = $c->stash->{site}->categories->find("$id")) {
            $out{active} = $cat->toggle_active;
            $out{ok} = 1;
        }
        else {
            $out{error} = "$id not found";
        }
    }
    else {
        $out{error} = "No param";
    }
    $c->stash(json => \%out);
    $c->detach($c->view('JSON'));
}

=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
