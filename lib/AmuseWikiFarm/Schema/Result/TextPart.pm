use utf8;
package AmuseWikiFarm::Schema::Result::TextPart;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::TextPart - Text sectioning

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

=head1 TABLE: C<text_part>

=cut

__PACKAGE__->table("text_part");

=head1 ACCESSORS

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 part_index

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 part_level

  data_type: 'integer'
  is_nullable: 0

=head2 part_title

  data_type: 'text'
  is_nullable: 0

=head2 part_size

  data_type: 'integer'
  is_nullable: 0

=head2 toc_index

  data_type: 'integer'
  is_nullable: 0

=head2 part_order

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "part_index",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "part_level",
  { data_type => "integer", is_nullable => 0 },
  "part_title",
  { data_type => "text", is_nullable => 0 },
  "part_size",
  { data_type => "integer", is_nullable => 0 },
  "toc_index",
  { data_type => "integer", is_nullable => 0 },
  "part_order",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</title_id>

=item * L</part_index>

=back

=cut

__PACKAGE__->set_primary_key("title_id", "part_index");

=head1 RELATIONS

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-10-03 14:44:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jdSZmYeaxXH0JBkKj8YS6Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
