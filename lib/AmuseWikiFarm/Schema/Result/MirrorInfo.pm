use utf8;
package AmuseWikiFarm::Schema::Result::MirrorInfo;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::MirrorInfo

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

=head1 TABLE: C<mirror_info>

=cut

__PACKAGE__->table("mirror_info");

=head1 ACCESSORS

=head2 mirror_info_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 mirror_origin_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sha1sum

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 download_destination

  data_type: 'text'
  is_nullable: 1

=head2 download_unix_timestamp

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "mirror_info_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "mirror_origin_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sha1sum",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "download_destination",
  { data_type => "text", is_nullable => 1 },
  "download_unix_timestamp",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</mirror_info_id>

=back

=cut

__PACKAGE__->set_primary_key("mirror_info_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<attachment_id_unique>

=over 4

=item * L</attachment_id>

=back

=cut

__PACKAGE__->add_unique_constraint("attachment_id_unique", ["attachment_id"]);

=head2 C<title_id_unique>

=over 4

=item * L</title_id>

=back

=cut

__PACKAGE__->add_unique_constraint("title_id_unique", ["title_id"]);

=head1 RELATIONS

=head2 attachment

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Attachment>

=cut

__PACKAGE__->belongs_to(
  "attachment",
  "AmuseWikiFarm::Schema::Result::Attachment",
  { id => "attachment_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 mirror_exclusions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::MirrorExclusion>

=cut

__PACKAGE__->has_many(
  "mirror_exclusions",
  "AmuseWikiFarm::Schema::Result::MirrorExclusion",
  { "foreign.mirror_info_id" => "self.mirror_info_id" },
  { cascade_copy => 0, cascade_delete => 0 },
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
    on_delete     => "SET NULL",
    on_update     => "CASCADE",
  },
);

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-08-06 07:41:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dnJ3LSkWXSCer8WNqkcLLw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
