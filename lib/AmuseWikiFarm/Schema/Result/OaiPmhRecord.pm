use utf8;
package AmuseWikiFarm::Schema::Result::OaiPmhRecord;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::OaiPmhRecord - OAI-PMH Records

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

=head1 TABLE: C<oai_pmh_record>

=cut

__PACKAGE__->table("oai_pmh_record");

=head1 ACCESSORS

=head2 identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 datestamp

  data_type: 'datetime'
  is_nullable: 1

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 metadata_identifier

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=head2 metadata_type

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 metadata_format

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 deleted

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "identifier",
  { data_type => "varchar", is_nullable => 0, size => 512 },
  "datestamp",
  { data_type => "datetime", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "metadata_identifier",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "metadata_type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "metadata_format",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "deleted",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</identifier>

=back

=cut

__PACKAGE__->set_primary_key("identifier");

=head1 RELATIONS

=head2 attachment

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Attachment>

=cut

__PACKAGE__->belongs_to(
  "attachment",
  "AmuseWikiFarm::Schema::Result::Attachment",
  { id => "attachment_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 oai_pmh_record_sets

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::OaiPmhRecordSet>

=cut

__PACKAGE__->has_many(
  "oai_pmh_record_sets",
  "AmuseWikiFarm::Schema::Result::OaiPmhRecordSet",
  { "foreign.oai_pmh_record_id" => "self.identifier" },
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

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 oai_pmh_sets

Type: many_to_many

Composing rels: L</oai_pmh_record_sets> -> oai_pmh_set

=cut

__PACKAGE__->many_to_many("oai_pmh_sets", "oai_pmh_record_sets", "oai_pmh_set");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-05-11 11:36:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WF7SNZSTbX/SCdgsJJUQKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
