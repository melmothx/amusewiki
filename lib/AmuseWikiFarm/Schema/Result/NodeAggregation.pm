use utf8;
package AmuseWikiFarm::Schema::Result::NodeAggregation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::NodeAggregation - Linking table from Node to Aggregation

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

=head1 TABLE: C<node_aggregation>

=cut

__PACKAGE__->table("node_aggregation");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 aggregation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "node_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "aggregation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</node_id>

=item * L</aggregation_id>

=back

=cut

__PACKAGE__->set_primary_key("node_id", "aggregation_id");

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

=head2 node

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "node",
  "AmuseWikiFarm::Schema::Result::Node",
  { node_id => "node_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-20 15:09:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Gvydp8JTZB69wD83NghIcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
