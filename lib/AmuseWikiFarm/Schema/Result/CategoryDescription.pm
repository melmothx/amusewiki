use utf8;
package AmuseWikiFarm::Schema::Result::CategoryDescription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::CategoryDescription - Category descriptions

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

=head1 TABLE: C<category_description>

=cut

__PACKAGE__->table("category_description");

=head1 ACCESSORS

=head2 category_description_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 muse_body

  data_type: 'text'
  is_nullable: 1

=head2 html_body

  data_type: 'text'
  is_nullable: 1

=head2 lang

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 last_modified_by

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 category_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "category_description_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "muse_body",
  { data_type => "text", is_nullable => 1 },
  "html_body",
  { data_type => "text", is_nullable => 1 },
  "lang",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "last_modified_by",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "category_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</category_description_id>

=back

=cut

__PACKAGE__->set_primary_key("category_description_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<category_id_lang_unique>

=over 4

=item * L</category_id>

=item * L</lang>

=back

=cut

__PACKAGE__->add_unique_constraint("category_id_lang_unique", ["category_id", "lang"]);

=head1 RELATIONS

=head2 category

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Category>

=cut

__PACKAGE__->belongs_to(
  "category",
  "AmuseWikiFarm::Schema::Result::Category",
  { id => "category_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lncC/VRWWnTcrfqNX8WC+w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
