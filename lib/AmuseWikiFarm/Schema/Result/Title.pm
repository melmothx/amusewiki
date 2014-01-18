use utf8;
package AmuseWikiFarm::Schema::Result::Title;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Title

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

=head1 TABLE: C<title>

=cut

__PACKAGE__->table("title");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 uri

  data_type: 'text'
  is_nullable: 1

=head2 site_id

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "uri",
  { data_type => "text", is_nullable => 1 },
  "site_id",
  { data_type => "varchar", is_nullable => 1, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 title_authors

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAuthor>

=cut

__PACKAGE__->has_many(
  "title_authors",
  "AmuseWikiFarm::Schema::Result::TitleAuthor",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 authors

Type: many_to_many

Composing rels: L</title_authors> -> author

=cut

__PACKAGE__->many_to_many("authors", "title_authors", "author");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-18 18:28:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fytz1j/BIkwHPIwWZ0f3QQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
