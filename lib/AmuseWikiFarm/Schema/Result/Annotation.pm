use utf8;
package AmuseWikiFarm::Schema::Result::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Annotation

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

=head1 TABLE: C<annotation>

=cut

__PACKAGE__->table("annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 annotation_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 annotation_type

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 priority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 private

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "annotation_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "annotation_type",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "priority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "private",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</annotation_id>

=back

=cut

__PACKAGE__->set_primary_key("annotation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_annotation_name_unique>

=over 4

=item * L</site_id>

=item * L</annotation_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "site_id_annotation_name_unique",
  ["site_id", "annotation_name"],
);

=head1 RELATIONS

=head2 aggregation_annotations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::AggregationAnnotation>

=cut

__PACKAGE__->has_many(
  "aggregation_annotations",
  "AmuseWikiFarm::Schema::Result::AggregationAnnotation",
  { "foreign.annotation_id" => "self.annotation_id" },
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

=head2 title_annotations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAnnotation>

=cut

__PACKAGE__->has_many(
  "title_annotations",
  "AmuseWikiFarm::Schema::Result::TitleAnnotation",
  { "foreign.annotation_id" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-18 18:05:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h1en/hmsPCQDSpHegRVMiA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
