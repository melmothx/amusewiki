package AmuseWikiFarm::Controller::Publish;
use Moose;
with 'AmuseWikiFarm::Role::Controller::HumanLoginScreen';
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Paginator;

=head1 NAME

AmuseWikiFarm::Controller::Publish - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller for publishing texts.

=head1 METHODS

=head2 root

Depending on the site mode, deny access to humans.
Stash the available revisions, depending on the site mode.

=cut

sub root :Chained('/site_human_required') :PathPart('publish') :CaptureArgs(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    $self->check_login($c) unless $site->human_can_publish;

    my $search = {};
    # if it's a librarian, we show all the pending revisions
    # while human can see only their own
    unless ($c->user_exists) {
        $search->{session_id} = $c->sessionid;
    }
    my $revs = $site->revisions
      ->search($search,
               { order_by => { -desc => 'updated' },
                 prefetch => [qw/title/],
               });
    $c->stash(revisions => $revs);
    $c->stash(full_page_no_side_columns => 1);
    log_debug { "Found " . $revs->count  . " Revisions" };
}

=head2 pending

Show the revisions not marked as pending

=head2 all

Show all revisions.

=cut

sub pending :Chained('root') :PathPart('pending') :Args(0) {
    my ($self, $c) = @_;
    my $revisions = delete $c->stash->{revisions};
    my $revs = $revisions->search([
                                   {
                                    'me.status' => 'pending'
                                   },
                                   {
                                    'me.status' => 'editing',
                                    'title.status' => 'editing'
                                   }
                                  ]);
    $c->stash(page_title => $c->loc('Pending revisions'));
    $c->stash(return => 'pending');
    $c->stash(revisions => $revs->as_list );
};

sub all :Chained('root') :PathPart('all') :Args {
    my ($self, $c, $page) = @_;
    unless ($page and $page =~ m/\A[1-9][0-9]*\z/) {
        $page = 1;
    }
    my $rs = $c->stash->{revisions};
    my $me = $rs->current_source_alias;
    my $revs = $rs->search(undef,
                           {
                            order_by => { -desc => ["$me.updated", "$me.id" ] },
                            page => $page,
                            rows => $c->stash->{site}->pagination_size,
                           });
    my $pager = $revs->pager;
    my $format_link = sub {
        return $c->uri_for_action('/publish/all', $_[0]);
    };
    $c->stash(
              pager => AmuseWikiFarm::Utils::Paginator::create_pager($pager, $format_link),
              revisions => $revs->as_list,
              page_title => $c->loc('All revisions'),
              return => 'all',
              template => 'publish/pending.tt',
             );
}


=head2 publish

Method to publish the texts.

=cut

sub validate_revision :Chained('root') :PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    if (my $revid = $c->request->params->{target}) {
        log_debug { "Found publish parameter, validating" };

        # revisions should be already stashed
        if (my $revs = $c->stash->{revisions}) {
            log_debug { "Found revision in stash" };

            # search that revision id
            if (my $found = $revs->find($revid)) {
                log_debug { "Found $revid!" };
                $c->stash(target_revision => $found);
                return;
            }
        }
    }
    $c->flash(error_msg => "Bad revision!");
    $c->res->redirect($c->uri_for_action('/publish/pending'));
    $c->detach();
}


sub publish :Chained('validate_revision') :PathPart('publish') :Args(0) {
    my ($self, $c) = @_;
    if (my $rev = $c->stash->{target_revision}) {
        # put a limit on accepting slow jobs
        unless ($c->model('DB::Job')->can_accept_further_jobs) {
            $c->flash->{error_msg} =
              $c->loc("Sorry, too many jobs pending, please try again later!");
            $c->res->redirect($c->uri_for_action('/publish/pending'));
            return;
        }

        if ($rev->pending) {
            log_debug { $rev->id . " is pending, processing!" };
            my $job = $c->stash->{site}->jobs
              ->publish_add($rev, ($c->user_exists ? $c->user->get("username") : ''));
            $c->res->redirect($c->uri_for_action('/tasks/display',
                                                 [$job->id]));
            return;
        }
    }
    # we don't care, this means the ui has been bypassed
    $c->detach('/not_found');
}

=head2 purge

Logged in users can delete revisions.

=cut

sub purge :Chained('validate_revision') :PathPart('purge') :Args(0) {
    my ($self, $c) = @_;
    if (my $rev = $c->stash->{target_revision}) {
        if ($c->user_exists) {
            my $uri = $rev->title->full_uri;
            $rev->delete;
            $c->flash(status_msg => $c->loc('Revision for [_1] has been deleted',
                                            $uri));
            my $return;
            if ($c->request->body_params->{return} and
                $c->request->body_params->{return} eq 'pending') {
                $return = $c->uri_for_action('/publish/pending');
            }
            else {
                $return = $c->uri_for_action('/publish/all');
            }
            $c->res->redirect($return);
            return;
        }
    }
    $c->detach('/not_found');
}


=head1 AUTHOR

Marco Pessotto <melmothx@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
