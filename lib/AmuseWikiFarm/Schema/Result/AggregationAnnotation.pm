use utf8;
package AmuseWikiFarm::Schema::Result::AggregationAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::AggregationAnnotation - Linking table for aggregation/annotations

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

=head1 TABLE: C<aggregation_annotation>

=cut

__PACKAGE__->table("aggregation_annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 annotation_value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "aggregation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "annotation_value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</annotation_id>

=item * L</aggregation_id>

=back

=cut

__PACKAGE__->set_primary_key("annotation_id", "aggregation_id");

=head1 RELATIONS

=head2 aggregation

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Aggregation>

=cut

__PACKAGE__->belongs_to(
  "aggregation",
  "AmuseWikiFarm::Schema::Result::Aggregation",
  { aggregation_id => "aggregation_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 annotation

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Annotation>

=cut

__PACKAGE__->belongs_to(
  "annotation",
  "AmuseWikiFarm::Schema::Result::Annotation",
  { annotation_id => "annotation_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-18 18:05:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:efoFWCPUB/Pa8H9GfGeFKA

__PACKAGE__->meta->make_immutable;
1;
