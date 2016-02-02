use utf8;
package AmuseWikiFarm::Schema::Result::SiteLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::SiteLink - Site links

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

=item * L<DBIx::Class::PassphraseColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "PassphraseColumn");

=head1 TABLE: C<site_link>

=cut

__PACKAGE__->table("site_link");

=head1 ACCESSORS

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 label

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "url",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "label",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-02-02 09:44:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KtsQDxR4CsrE7co0gIqdVw

__PACKAGE__->meta->make_immutable;
1;
