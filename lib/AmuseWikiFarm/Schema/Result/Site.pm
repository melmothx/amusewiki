use utf8;
package AmuseWikiFarm::Schema::Result::Site;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Site

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

=head1 TABLE: C<site>

=cut

__PACKAGE__->table("site");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 site_id

  data_type: 'varchar'
  default_value: 'default'
  is_nullable: 0
  size: 16

=head2 locale

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "site_id",
  {
    data_type => "varchar",
    default_value => "default",
    is_nullable => 0,
    size => 16,
  },
  "locale",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
);

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-20 19:06:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KjWWd2DzGNd2t71/KRV/Hg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
