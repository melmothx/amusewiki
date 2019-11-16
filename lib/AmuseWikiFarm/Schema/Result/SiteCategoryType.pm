use utf8;
package AmuseWikiFarm::Schema::Result::SiteCategoryType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::SiteCategoryType

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

=head1 TABLE: C<site_category_type>

=cut

__PACKAGE__->table("site_category_type");

=head1 ACCESSORS

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 category_type

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 active

  data_type: 'smallint'
  default_value: 1
  is_nullable: 0

=head2 priority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 name_singular

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name_plural

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "category_type",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "active",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "priority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "name_singular",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name_plural",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</site_id>

=item * L</category_type>

=back

=cut

__PACKAGE__->set_primary_key("site_id", "category_type");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2019-11-16 11:01:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mvkxzurO+uiYrdGz00M17A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
