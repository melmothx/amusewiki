use utf8;
package AmuseWikiFarm::Schema::Result::BulkJob;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::BulkJob - Aggregated jobs

=cut

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<bulk_job>

=cut

__PACKAGE__->table("bulk_job");

=head1 ACCESSORS

=head2 bulk_job_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 task

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 created

  data_type: 'datetime'
  is_nullable: 0

=head2 started

  data_type: 'datetime'
  is_nullable: 1

=head2 completed

  data_type: 'datetime'
  is_nullable: 1

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 payload

  data_type: 'text'
  is_nullable: 1

=head2 username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "bulk_job_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "task",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "started",
  { data_type => "datetime", is_nullable => 1 },
  "completed",
  { data_type => "datetime", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "payload",
  { data_type => "text", is_nullable => 1 },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bulk_job_id>

=back

=cut

__PACKAGE__->set_primary_key("bulk_job_id");

=head1 RELATIONS

=head2 jobs

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Job>

=cut

__PACKAGE__->has_many(
  "jobs",
  "AmuseWikiFarm::Schema::Result::Job",
  { "foreign.bulk_job_id" => "self.bulk_job_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-08-28 09:54:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5e1pzUF928SaKo/w4es7oQ

use DateTime;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse qw/to_json from_json/;

before delete => sub {
    my $self = shift;
    # we delete them manually to trigger the log cleanup. If we let
    # this happen with cascade, we lose the trigger. However, deleting
    # large bulks becomes very slow.
    $self->jobs->delete_all;
};

sub completed_locale {
    my ($self, $locale) = @_;
    return $self->_format_dt_locale($self->completed, $locale)
}

sub created_locale {
    my ($self, $locale) = @_;
    return $self->_format_dt_locale($self->created, $locale)
}

sub _format_dt_locale {
    my ($self, $datetime, $locale) = @_;
    $locale ||= 'en';
    if ($datetime) {
        my $dt = DateTime->from_object(object => $datetime,
                                       locale => $locale,
                                      );
        $dt->set_time_zone('UTC');
        return $dt->format_cldr($dt->locale->datetime_format_full);
    }
    else {
        return '';
    }
}

sub total_jobs {
    my ($self) = @_;
    return $self->jobs->count;
}

sub total_failed_jobs {
    my ($self) = @_;
    return $self->jobs->failed_jobs->count;
}

sub total_completed_jobs {
    my ($self) = @_;
    return $self->jobs->completed_jobs->count;
}

sub eta {
    my ($self) = @_;
    if (my $done = $self->completed) {
        return $done;
    }
    if ($self->started) {
        if (my $finished = $self->jobs->finished_jobs->count) {
            # extremely verbose but clear, hopefully
            my $total = $self->total_jobs;
            my $started = $self->started->clone;
            my $to_go = $total - $finished;
            my $now_epoch = time();
            my $started_epoch = $started->epoch;
            my $elapsed = $now_epoch - $started_epoch;
            my $average = $elapsed / $finished;
            my $expected = $to_go * $average;
            return DateTime->now->add(seconds => $expected);
        }
    }
    return undef;
}
sub eta_locale {
    my ($self, $locale) = @_;
    return $self->_format_dt_locale($self->eta, $locale)
}

sub check_and_set_complete {
    my $self = shift;
    log_debug { "check if the jobs are complete" };
    $self->discard_changes; # ensure it's refetch
    if (!$self->started) {
        # first call, set started
        $self->update({ started => DateTime->now });
    }
    elsif (!$self->completed && !$self->jobs->unfinished->count) {
        log_debug { "no unfinished jobs" };
        $self->handle_bulk_job_completed;
        $self->update({
                       completed => DateTime->now,
                       status => 'completed',
                      });
    }
}

sub abort_jobs {
    my $self = shift;
    return if $self->completed;
    my $guard = $self->result_source->schema->txn_scope_guard;
    log_debug { "aborting job" };
    $self->jobs->pending->update({
                                  status => 'completed',
                                  completed => DateTime->now,
                                  errors => 'Bulk job aborted',
                                 });
    $self->update({
                   status => 'aborted',
                   completed => DateTime->now,
                  });
    $guard->commit;
}

sub is_reindex {
    return shift->task eq 'reindex';
}

sub is_rebuild {
    return shift->task eq 'rebuild';
}

sub is_mirror {
    return shift->task eq 'mirror';
}

sub job_title {
    my $self = shift;
    my $site = $self->site;
    if ($self->is_mirror) {
        if (my $data = $self->decoded_payload) {
            if (my $mid = $data->{mirror_origin_id}) {
                if (my $origin = $site->mirror_origins->find($mid)) {
                    return $origin->remote_target_url;
                }
            }
        }
    }
    return $site->sitename || $site->canonical;
}


sub handle_bulk_job_completed {
    my $self = shift;
    if ($self->is_mirror) {
        # add the job to copy the files over to their destination + git.
        $self->site->jobs->enqueue(install_downloaded  => $self->decoded_payload, $self->username);
    }
}

sub decoded_payload {
    my $self = shift;
    my $data;
    if (my $json = $self->payload) {
        eval { $data = from_json($json) };
    }
    return $data;
}

sub expected_documents {
    my $self = shift;
    my @out;
    my $base = $self->site->canonical_url;
    foreach my $j ($self->jobs) {
        my $payload = $j->job_data;
        if (my $path = $payload->{path}) {
            if ($path =~ m{[a-z0-9]/[a-z0-9][a-z0-9]/([a-z0-9-]+)\.muse}) {
                push @out, $base . "/library/$1";
            }
            elsif ($path =~ m{specials/([a-z0-9-]+)\.muse}) {
                push @out, $base . "/special/$1";
            }
        }
    }
    return [ sort @out ];
}


__PACKAGE__->meta->make_immutable;
1;
