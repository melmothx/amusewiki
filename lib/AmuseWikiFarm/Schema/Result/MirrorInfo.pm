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

=head2 checksum

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 download_destination

  data_type: 'text'
  is_nullable: 1

=head2 mirror_exception

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 last_updated

  data_type: 'datetime'
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
  "checksum",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "download_destination",
  { data_type => "text", is_nullable => 1 },
  "mirror_exception",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "last_updated",
  { data_type => "datetime", is_nullable => 1 },
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


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-08-18 15:29:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:88Uzk1uSoCD5VnWH/pW66g

use Digest::SHA;
use DateTime;

sub compute_checksum {
    my $self = shift;
    if (my $file = $self->get_file_path) {
        if (-f $file) {
            $self->update({
                           checksum => Digest::SHA->new('SHA-1')->addfile($file)->hexdigest,
                           last_updated => DateTime->now,
                          });
        }
    }
}

sub get_file_path {
    my $self = shift;
    if (my $obj = $self->attachment || $self->title) {
        return $obj->f_full_path_name;
    }
    else {
        return;
    }
}

sub full_uri {
    my $self = shift;
    my $obj = $self->attachment || $self->title;
    return $obj->full_uri;
}

sub is_attachment {
    shift->attachment_id ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;
1;
