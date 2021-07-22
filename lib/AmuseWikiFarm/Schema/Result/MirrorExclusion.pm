use utf8;
package AmuseWikiFarm::Schema::Result::MirrorExclusion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::MirrorExclusion

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

=head1 TABLE: C<mirror_exclusion>

=cut

__PACKAGE__->table("mirror_exclusion");

=head1 ACCESSORS

=head2 mirror_exclusion_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 mirror_origin_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 mirror_info_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 exclusion_type

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 exclusion_timestamp

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mirror_exclusion_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "mirror_origin_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "mirror_info_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "exclusion_type",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "exclusion_timestamp",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mirror_exclusion_id>

=back

=cut

__PACKAGE__->set_primary_key("mirror_exclusion_id");

=head1 RELATIONS

=head2 mirror_info

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::MirrorInfo>

=cut

__PACKAGE__->belongs_to(
  "mirror_info",
  "AmuseWikiFarm::Schema::Result::MirrorInfo",
  { mirror_info_id => "mirror_info_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 mirror_origin

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::MirrorOrigin>

=cut

__PACKAGE__->belongs_to(
  "mirror_origin",
  "AmuseWikiFarm::Schema::Result::MirrorOrigin",
  { mirror_origin_id => "mirror_origin_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-30 10:11:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rN6tjc2g5mIPfVxna5dQKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
