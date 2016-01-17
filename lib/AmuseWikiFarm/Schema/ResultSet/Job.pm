package AmuseWikiFarm::Schema::ResultSet::Job;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use JSON qw/to_json from_json/;
use AmuseWikiFarm::Utils::Amuse qw/clean_username/;
use AmuseWikiFarm::Log::Contextual;

=head1 NAME

AmuseWikiFarm::Schema::ResultSet::Job

=head1 SYNOPSIS

This resultset has a couple of convenience methods to enqueu and
retrieve jobs (formerly located at AmuseWikiFarm::Archive::Queue, now
dismissed.

All the methods here assume that this class was created with
$site->jobs, hence picking up the site_id. Otherwise it will start
throwing exceptions everywhere.

=head1 METHODS

=head2 handled_jobs_hashref

Return a hashref with the handled jobs as keys and true as value.

=head2 enqueue($task, $payload, $priority, $username)

Enqueye the task C<$task>, with the payload C<$payload>, at priority
C<$priority>, with $username as owner.

$payload must be an hashref.

=cut

sub _handled_jobs {
    return qw/testing publish git bookbuilder purge
              alias_delete alias_create/;
}

sub handled_jobs_hashref {
    my $self = shift;
    my %hash = map { $_ => 1 } $self->_handled_jobs;
    return \%hash;
}

sub enqueue {
    my ($self, $task, $payload, $priority, $username) = @_;

    # validate
    die "Missing task and/or payload: $task $payload" unless $task && $payload;
    die unless (ref($payload) && (ref($payload) eq 'HASH'));
    die "Unhandled job $task" unless $self->handled_jobs_hashref->{$task};

    my $insertion = {
                     task    => $task,
                     payload => to_json($payload, { pretty => 1 }),
                     status  => 'pending',
                     created => DateTime->now,
                     priority => $priority || 10,
                     username => clean_username($username),
                    };
    my $job = $self->create($insertion)->discard_changes;
    $job->make_room_for_logs;
    return $job;
}

=head2 bookbuilder_add ($payload)

Add a bookbuilder job with the payload.

=head2 publish_add($revision, $username)

Schedule the revision object $revision for publishing. As a side
effect, the status of the revision will be changed to C<processing>.

The payload will be

 { id => $revision->id }

=cut

sub bookbuilder_add {
    my ($self, $payload) = @_;
    return $self->enqueue(bookbuilder => $payload, 3);
}

sub publish_add {
    my ($self, $revision, $username) = @_;
    return $self->enqueue(publish => { id => $revision->id }, 5, $username);
}

sub git_action_add {
    my ($self, $payload) = @_;
    return $self->enqueue(git => $payload);
}

sub purge_add {
    my ($self, $payload, $username) = @_;
    return $self->enqueue(purge => $payload, 10, $username);
}

sub alias_delete_add {
    my ($self, $payload) = @_;
    return $self->enqueue(alias_delete => $payload);
}

sub alias_create_add {
    my ($self, $payload) = @_;
    return $self->enqueue(alias_create => $payload);
}

=head2 dequeue

Extract the first pending job, sorted by priority and timestamp.

=cut

sub dequeue {
    my $self = shift;
    my $job = $self->pending->first;
    return unless $job;
    $job->status('taken');
    $job->update;
    return $job;
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
    return shift->search({
                          status => 'pending',
                         },
                         {
                          order_by => [qw/priority
                                          created/],
                         });
}

sub can_accept_further_jobs {
    my $self = shift;
    my $total_pending = $self->pending->count;
    if ($total_pending < 50) {
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

sub purge_old_jobs {
    my $self = shift;
    my $reftime = DateTime->now;
    # after one month, delete the revisions and jobs
    $reftime->subtract(months => 1);
    my $old_jobs = $self->completed_older_than($reftime);
    while (my $job = $old_jobs->next) {
        die unless $job->status eq 'completed'; # shouldn't happen
        log_warn { "Removing old job " . $job->id . " for site " . $job->site->id .
                     " and task " . $job->task };
        $job->delete;
    }
}


1;
