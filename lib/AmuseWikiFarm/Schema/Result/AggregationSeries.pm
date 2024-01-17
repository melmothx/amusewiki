use utf8;
package AmuseWikiFarm::Schema::Result::AggregationSeries;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::AggregationSeries

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

=head1 TABLE: C<aggregation_series>

=cut

__PACKAGE__->table("aggregation_series");

=head1 ACCESSORS

=head2 aggregation_series_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 aggregation_series_uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 aggregation_series_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 publisher

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publication_place

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "aggregation_series_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "aggregation_series_uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "aggregation_series_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "publisher",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publication_place",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregation_series_id>

=back

=cut

__PACKAGE__->set_primary_key("aggregation_series_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<aggregation_series_uri_site_id_unique>

=over 4

=item * L</aggregation_series_uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "aggregation_series_uri_site_id_unique",
  ["aggregation_series_uri", "site_id"],
);

=head1 RELATIONS

=head2 aggregations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Aggregation>

=cut

__PACKAGE__->has_many(
  "aggregations",
  "AmuseWikiFarm::Schema::Result::Aggregation",
  { "foreign.aggregation_series_id" => "self.aggregation_series_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-16 13:27:46
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UpqlD6YsIbNWLwKSJzjEAA

sub bump_oai_pmh_records {
    my $self = shift;
    foreach my $agg ($self->aggregations) {
        $agg->bump_oai_pmh_records;
    }
}


__PACKAGE__->meta->make_immutable;
1;
