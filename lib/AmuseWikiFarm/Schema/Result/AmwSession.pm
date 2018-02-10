use utf8;
package AmuseWikiFarm::Schema::Result::AmwSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::AmwSession - Session backend

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

=head1 TABLE: C<amw_session>

=cut

__PACKAGE__->table("amw_session");

=head1 ACCESSORS

=head2 session_id

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 expires

  data_type: 'integer'
  is_nullable: 1

=head2 session_data

  data_type: 'blob'
  is_nullable: 1

=head2 flash_data

  data_type: 'blob'
  is_nullable: 1

=head2 generic_data

  data_type: 'blob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "session_id",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "expires",
  { data_type => "integer", is_nullable => 1 },
  "session_data",
  { data_type => "blob", is_nullable => 1 },
  "flash_data",
  { data_type => "blob", is_nullable => 1 },
  "generic_data",
  { data_type => "blob", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</site_id>

=item * L</session_id>

=back

=cut

__PACKAGE__->set_primary_key("site_id", "session_id");

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


# Created by DBIx::Class::Schema::Loader v0.07046 @ 2018-02-05 17:28:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MbbGB9a/lSYdTvsbOR38XA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
