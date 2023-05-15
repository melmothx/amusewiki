use utf8;
package AmuseWikiFarm::Schema::Result::OaiPmhRecordSet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::OaiPmhRecordSet - OAI-PMH brigde table between records and sets

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

=head1 TABLE: C<oai_pmh_record_set>

=cut

__PACKAGE__->table("oai_pmh_record_set");

=head1 ACCESSORS

=head2 oai_pmh_record_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 oai_pmh_set_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "oai_pmh_record_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "oai_pmh_set_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</oai_pmh_record_id>

=item * L</oai_pmh_set_id>

=back

=cut

__PACKAGE__->set_primary_key("oai_pmh_record_id", "oai_pmh_set_id");

=head1 RELATIONS

=head2 oai_pmh_record

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::OaiPmhRecord>

=cut

__PACKAGE__->belongs_to(
  "oai_pmh_record",
  "AmuseWikiFarm::Schema::Result::OaiPmhRecord",
  { oai_pmh_record_id => "oai_pmh_record_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 oai_pmh_set

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::OaiPmhSet>

=cut

__PACKAGE__->belongs_to(
  "oai_pmh_set",
  "AmuseWikiFarm::Schema::Result::OaiPmhSet",
  { oai_pmh_set_id => "oai_pmh_set_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-05-15 14:35:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YNpaP+4nAvLqF61kWGpDkw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
