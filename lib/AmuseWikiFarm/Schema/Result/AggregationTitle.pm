use utf8;
package AmuseWikiFarm::Schema::Result::AggregationTitle;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::AggregationTitle - Linking table for aggregations

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

=head1 TABLE: C<aggregation_title>

=cut

__PACKAGE__->table("aggregation_title");

=head1 ACCESSORS

=head2 aggregation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title_uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "aggregation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title_uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</aggregation_id>

=item * L</title_uri>

=back

=cut

__PACKAGE__->set_primary_key("aggregation_id", "title_uri");

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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-13 09:21:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sWGh42sQQufnaBcfGb18lQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
