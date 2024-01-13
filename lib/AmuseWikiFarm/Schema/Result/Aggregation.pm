use utf8;
package AmuseWikiFarm::Schema::Result::Aggregation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Aggregation

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

=head1 TABLE: C<aggregation>

=cut

__PACKAGE__->table("aggregation");

=head1 ACCESSORS

=head2 aggregation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 aggregation_uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 series_number

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 publication_place

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publication_date

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 isbn

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 publisher

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "aggregation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "aggregation_uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "series_number",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "publication_place",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publication_date",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "isbn",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "publisher",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregation_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<aggregation_uri_site_id_unique>

=over 4

=item * L</aggregation_uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "aggregation_uri_site_id_unique",
  ["aggregation_uri", "site_id"],
);

=head1 RELATIONS

=head2 aggregation_titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::AggregationTitle>

=cut

__PACKAGE__->has_many(
  "aggregation_titles",
  "AmuseWikiFarm::Schema::Result::AggregationTitle",
  { "foreign.aggregation_id" => "self.aggregation_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-13 08:51:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OvK/gLRxFR/f+YzIcud0BQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
