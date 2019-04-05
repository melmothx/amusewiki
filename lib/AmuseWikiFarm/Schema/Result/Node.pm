use utf8;
package AmuseWikiFarm::Schema::Result::Node;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Node - Nestable nodes

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

=head1 TABLE: C<node>

=cut

__PACKAGE__->table("node");

=head1 ACCESSORS

=head2 node_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 parent_node_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "node_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "parent_node_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</node_id>

=back

=cut

__PACKAGE__->set_primary_key("node_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_uri_unique>

=over 4

=item * L</site_id>

=item * L</uri>

=back

=cut

__PACKAGE__->add_unique_constraint("site_id_uri_unique", ["site_id", "uri"]);

=head1 RELATIONS

=head2 node_bodies

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeBody>

=cut

__PACKAGE__->has_many(
  "node_bodies",
  "AmuseWikiFarm::Schema::Result::NodeBody",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_categories

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeCategory>

=cut

__PACKAGE__->has_many(
  "node_categories",
  "AmuseWikiFarm::Schema::Result::NodeCategory",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeTitle>

=cut

__PACKAGE__->has_many(
  "node_titles",
  "AmuseWikiFarm::Schema::Result::NodeTitle",
  { "foreign.node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 nodes

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AmuseWikiFarm::Schema::Result::Node",
  { "foreign.parent_node_id" => "self.node_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 parent_node

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->belongs_to(
  "parent_node",
  "AmuseWikiFarm::Schema::Result::Node",
  { node_id => "parent_node_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
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

=head2 categories

Type: many_to_many

Composing rels: L</node_categories> -> category

=cut

__PACKAGE__->many_to_many("categories", "node_categories", "category");

=head2 titles

Type: many_to_many

Composing rels: L</node_titles> -> title

=cut

__PACKAGE__->many_to_many("titles", "node_titles", "title");


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2019-04-05 08:15:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wvwnVE7iZWdNMtXhrabmuA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
