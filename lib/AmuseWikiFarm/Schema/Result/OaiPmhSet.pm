use utf8;
package AmuseWikiFarm::Schema::Result::OaiPmhSet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::OaiPmhSet - OAI-PMH Sets definition

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

=head1 TABLE: C<oai_pmh_set>

=cut

__PACKAGE__->table("oai_pmh_set");

=head1 ACCESSORS

=head2 oai_pmh_set_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 set_spec

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 set_name

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "oai_pmh_set_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "set_spec",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "set_name",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</oai_pmh_set_id>

=back

=cut

__PACKAGE__->set_primary_key("oai_pmh_set_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<set_spec_site_id_unique>

=over 4

=item * L</set_spec>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("set_spec_site_id_unique", ["set_spec", "site_id"]);

=head1 RELATIONS

=head2 oai_pmh_record_sets

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::OaiPmhRecordSet>

=cut

__PACKAGE__->has_many(
  "oai_pmh_record_sets",
  "AmuseWikiFarm::Schema::Result::OaiPmhRecordSet",
  { "foreign.oai_pmh_set_id" => "self.oai_pmh_set_id" },
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

=head2 oai_pmh_records

Type: many_to_many

Composing rels: L</oai_pmh_record_sets> -> oai_pmh_record

=cut

__PACKAGE__->many_to_many("oai_pmh_records", "oai_pmh_record_sets", "oai_pmh_record");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-05-12 17:16:20
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3eULPtUvgg1EVQj7Cy4Bpg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
