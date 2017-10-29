use utf8;
package AmuseWikiFarm::Schema::Result::GlobalSiteFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::GlobalSiteFile - Files which site uses

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

=head1 TABLE: C<global_site_files>

=cut

__PACKAGE__->table("global_site_files");

=head1 ACCESSORS

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 attachment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 file_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 file_type

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 file_path

  data_type: 'text'
  is_nullable: 0

=head2 image_width

  data_type: 'integer'
  is_nullable: 1

=head2 image_height

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "attachment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "file_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "file_type",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "file_path",
  { data_type => "text", is_nullable => 0 },
  "image_width",
  { data_type => "integer", is_nullable => 1 },
  "image_height",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</site_id>

=item * L</file_name>

=back

=cut

__PACKAGE__->set_primary_key("site_id", "file_name");

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-10-29 09:48:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NN5qBAlfstPYQQEA81PWkA


sub is_image {
    my $self = shift;
    if ($self->file_name =~ m/\.(jpe?g|png)/) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_public {
    my $self = shift;
    if ($self->file_name =~ m/[a-z0-9]
                              \.
                              (
                                  png | jpe?g | gif | ico | otf | ttf | woff |
                                  torrent | txt | css | js
                              )\Z/x) {
        return 1;
    }
    else {
        return 0;
    }
}


__PACKAGE__->meta->make_immutable;
1;
