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

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

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

=head2 completed

  data_type: 'datetime'
  is_nullable: 1

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

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
  "completed",
  { data_type => "datetime", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-11-12 17:15:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:beXju8kw3LlA0w1doMmDsQ


sub is_completed {
    my $self = shift;
    return !$self->jobs->unfinished->count;
}

before delete => sub {
    my $self = shift;
    $self->jobs->delete_all;
};

__PACKAGE__->meta->make_immutable;
1;
