package AmuseWikiFarm::Schema::ResultSet::Job;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use AmuseWikiFarm::Utils::Amuse qw/clean_username to_json/;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Job - Job resultset

=head1 SYNOPSIS

This resultset has a couple of convenience methods to enqueu and
retrieve jobs.

All the methods here assume that this class was created with
$site->jobs, hence picking up the site_id. Otherwise it will start
throwing exceptions everywhere.

=head1 METHODS

=head2 handled_jobs_hashref

Return a hashref with the handled jobs as keys and the priority as
value (always true).

=head2 enqueue($task, $payload, $username)

Enqueye the task C<$task>, with the payload C<$payload>, at priority
C<$priority>, with $username as owner.

$payload must be an hashref.

=cut

sub handled_jobs_hashref {
    return {
            purge => 2,
            alias_delete => 3,
            alias_create => 4,
            publish => 5,
            bookbuilder => 6,
            git => 7,
            hourly_job => 9,
            daily_job => 10,
            rebuild => 20,
            reindex => 19,
            build_custom_format => 25, # after publish/rebuild/reindex but before the static indexes
            build_static_indexes => 30,
            # testing
            testing => 10,
            testing_high => 5,
           };
}

sub unfinished {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => { -not_in => [qw/failed completed/]}});
}

sub finished_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => [qw/failed completed/] });
}

sub failed_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => 'failed' });
}

sub completed_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.status" => 'completed' });
}

sub enqueue {
    my ($self, $task, $payload, $username) = @_;

    # validate
    die "Missing task and/or payload: $task $payload" unless $task && $payload;
    die "payload $payload is an hashref" unless (ref($payload) && (ref($payload) eq 'HASH'));
    my $priority = $self->handled_jobs_hashref->{$task};
    die "Unhandled job $task" unless $priority;

    my $insertion = {
                     task    => $task,
                     payload => to_json($payload),
                     status  => 'pending',
                     created => DateTime->now,
                     priority => $priority,
                     username => ($username ? clean_username($username) : undef),
                    };
    my $job = $self->create($insertion)->discard_changes;
    $job->make_room_for_logs;
    return $job;
}

sub enqueue_global_job {
    my ($self, $task, $payload) = @_;
    $payload ||= {};
    my $site = $self->result_source->schema->resultset('Site')->first;
    return unless $site;
    die "payload $payload is an hashref" unless (ref($payload) && (ref($payload) eq 'HASH'));
    my $priority = $self->handled_jobs_hashref->{$task};
    die "Unhandled job $task" unless $priority;
    my $insertion = {
                     task    => $task,
                     payload => to_json($payload),
                     status  => 'pending',
                     created => DateTime->now,
                     priority => $priority,
                     site => $site,
                    };
    my $job = $self->create($insertion)->discard_changes;
    $job->make_room_for_logs;
    return $job;
}

=head2 bookbuilder_add ($payload)

Add a bookbuilder job with the payload.

=head2 publish_add($revision, $username)

Schedule the revision object $revision for publishing.

The payload will be

 { id => $revision->id }

=cut

sub bookbuilder_add {
    my ($self, $payload) = @_;
    return $self->enqueue(bookbuilder => $payload);
}

sub publish_add {
    my ($self, $revision, $username) = @_;
    return $self->enqueue(publish => { id => $revision->id }, $username);
}

=head2 git_action_add($payload)

Enqueue a git action.

=head2 purge_add($payload, $username)

Enqueue a purging action.

=head2 alias_create_add($payload)

Enqueue an alias creation action.

=head2 alias_delete_add($payload)

Enqueue an alias deletion action.

=cut

sub git_action_add {
    my ($self, $payload, $username) = @_;
    return $self->enqueue(git => $payload, $username);
}

sub purge_add {
    my ($self, $payload, $username) = @_;
    return $self->enqueue(purge => $payload, $username);
}

sub alias_delete_add {
    my ($self, $payload, $username) = @_;
    return $self->enqueue(alias_delete => $payload, $username);
}

sub alias_create_add {
    my ($self, $payload, $username) = @_;
    return $self->enqueue(alias_create => $payload, $username);
}

sub rebuild_add {
    my ($self, $payload, $username) = @_;
    die "Missing id" unless $payload->{id};
    return $self->enqueue(rebuild => $payload, $username);
}

sub reindex_add {
    my ($self, $payload, $username) = @_;
    die "Missing path" unless $payload->{path};
    return $self->enqueue(reindex => $payload, $username);
}


=head2 dequeue

Return the first pending job, sorted by priority and timestamp, if any.

=head2 pending

Return a resultset for C<status> equal to C<pending>, sorted by
priority and created.

=cut

sub dequeue {
    return shift->pending->first;
}

=head2 fetch_job_by_id_json($id)

Return the json representation of the job, or a serialized hashref with:

 { errors => 'No such job' }

=cut

sub fetch_job_by_id_json {
    my ($self, $id) = @_;
    my $job = $self->find($id);
    return to_json({ errors => 'No such job' }) unless $job;
    return $job->as_json;
}

sub pending {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.status" => 'pending',
                         },
                         {
                          order_by => ["$me.priority",
                                       "$me.created",
                                       "$me.id" ],
                         });
}

sub build_static_indexes_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.task" => 'build_static_indexes' });
}

sub build_custom_format_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({ "$me.task" => 'build_custom_format' });
}

sub build_custom_format_add {
    my ($self, $payload, $username) = @_;
    die "Missing required keys id and cf" unless $payload->{id} && $payload->{cf};
    return $self->enqueue(build_custom_format => $payload, $username);
}

sub build_static_indexes_add {
    my ($self) = @_;
    return $self->enqueue(build_static_indexes => {});
}

sub exclude_bulks {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.bulk_job_id" => undef,
                         });
}

sub exclude_low_priority {
    my $self = shift;
    my $me = $self->current_source_alias;
    return $self->search({
                          "$me.priority" => { '<' => 10 },
                         });
}

=head2 can_accept_further_jobs

Return true if the number of pending jobs is lesser than 50.

=cut

sub can_accept_further_jobs {
    if (shift->pending->exclude_bulks->exclude_low_priority->count < 50) {
        return 1;
    }
    else {
        return;
    }
}

=head2 completed_older_than($datetime)

Return the resultset for the completed jobs older than the
datetime object passed as argument.

=cut

sub completed_older_than {
    my ($self, $time) = @_;
    die unless $time && $time->isa('DateTime');
    my $format_time = $self->result_source->schema->storage->datetime_parser
      ->format_datetime($time);
    return $self->search({
                          status => 'completed',
                          completed => { '<' => $format_time },
                         });
}

=head2 purge_old_jobs

Find all completed jobs older than 1 months and call C<delete> on each
of them, so attached files are removed correctly.

=cut

sub purge_old_jobs {
    my $self = shift;
    my $reftime = DateTime->now;
    # after one month, delete the revisions and jobs
    $reftime->subtract(months => 1);
    my $old_jobs = $self->completed_older_than($reftime);
    while (my $job = $old_jobs->next) {
        die unless $job->status eq 'completed'; # shouldn't happen
        log_info { "Removing old job " . $job->id . " for site " . $job->site->id .
                     " and task " . $job->task };
        $job->delete;
    }
}

=head2 fail_stale_jobs

Meant to be called by the jobber before dispatching a new job: check
for stale jobs (due, e.g. to a crash, or db connection failing, etc.).

=cut

sub fail_stale_jobs {
    my $self = shift;
    my $me = $self->current_source_alias;
    my $reftime = $self->result_source->schema->storage->datetime_parser
      ->format_datetime(DateTime->now->subtract(hours => 1));
    $self->search({
                   "$me.status" => 'taken',
                   "$me.created" => { '<', $reftime },
                  })
      ->update({ status => 'failed',
                 errors => "Job aborted, please try again" });
}

1;
