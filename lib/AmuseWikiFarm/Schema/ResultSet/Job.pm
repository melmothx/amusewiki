package AmuseWikiFarm::Schema::ResultSet::Job;

use utf8;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

use DateTime;
use JSON qw/to_json from_json/;

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

=head2 enqueue($task, $payload, $priority)

Enqueye the task C<$task>, with the payload C<$payload>, at priority
C<$priority>.

$payload must be an hashref.

=cut

sub _handled_jobs {
    return qw/testing publish git bookbuilder/;
}

sub handled_jobs_hashref {
    my $self = shift;
    my %hash = map { $_ => 1 } $self->_handled_jobs;
    return \%hash;
}

sub enqueue {
    my ($self, $task, $payload, $priority) = @_;

    # validate
    die "Missing task and/or payload: $task $payload" unless $task && $payload;
    die unless (ref($payload) && (ref($payload) eq 'HASH'));
    die "Unhandled job $task" unless $self->handled_jobs_hashref->{$task};

    my $insertion = {
                     task    => $task,
                     payload => to_json($payload),
                     status  => 'pending',
                     created => DateTime->now,
                     priority => $priority || 10,
                    };
    return $self->create($insertion)->get_from_storage;
}

=head2 bookbuilder_add ($payload)

Add a bookbuilder job with the payload.

=head2 publish_add($revision)

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
    my ($self, $revision) = @_;
    # see Result::Revision for the status
    $revision->status('processing');
    $revision->update;
    return $self->enqueue(publish => { id => $revision->id }, 5);
}

sub git_action_add {
    my ($self, $payload) = @_;
    return $self->enqueue(git => $payload);
}

=head2 dequeue

Extract the first pending job, sorted by priority and timestamp.

=cut

sub dequeue {
    my $self = shift;
    my $job = $self->search({
                             status => 'pending',
                            },
                            {
                             order_by => [qw/priority
                                             created/],
                            })->first;
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

1;
