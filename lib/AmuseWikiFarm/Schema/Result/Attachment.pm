use utf8;
package AmuseWikiFarm::Schema::Result::Attachment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Attachment - Attachment to texts

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

=head1 TABLE: C<attachment>

=cut

__PACKAGE__->table("attachment");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 f_path

  data_type: 'text'
  is_nullable: 0

=head2 f_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 f_archive_rel_path

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 f_timestamp

  data_type: 'datetime'
  is_nullable: 0

=head2 f_timestamp_epoch

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 f_full_path_name

  data_type: 'text'
  is_nullable: 0

=head2 f_suffix

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 f_class

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 title_muse

  data_type: 'text'
  is_nullable: 1

=head2 comment_muse

  data_type: 'text'
  is_nullable: 1

=head2 title_html

  data_type: 'text'
  is_nullable: 1

=head2 comment_html

  data_type: 'text'
  is_nullable: 1

=head2 mime_type

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "f_path",
  { data_type => "text", is_nullable => 0 },
  "f_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_archive_rel_path",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "f_timestamp",
  { data_type => "datetime", is_nullable => 0 },
  "f_timestamp_epoch",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 0 },
  "f_suffix",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "f_class",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "title_muse",
  { data_type => "text", is_nullable => 1 },
  "comment_muse",
  { data_type => "text", is_nullable => 1 },
  "title_html",
  { data_type => "text", is_nullable => 1 },
  "comment_html",
  { data_type => "text", is_nullable => 1 },
  "mime_type",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<uri_site_id_unique>

=over 4

=item * L</uri>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_site_id_unique", ["uri", "site_id"]);

=head1 RELATIONS

=head2 global_site_files

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::GlobalSiteFile>

=cut

__PACKAGE__->has_many(
  "global_site_files",
  "AmuseWikiFarm::Schema::Result::GlobalSiteFile",
  { "foreign.attachment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mirror_info

Type: might_have

Related object: L<AmuseWikiFarm::Schema::Result::MirrorInfo>

=cut

__PACKAGE__->might_have(
  "mirror_info",
  "AmuseWikiFarm::Schema::Result::MirrorInfo",
  { "foreign.attachment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
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

=head2 title_attachments

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAttachment>

=cut

__PACKAGE__->has_many(
  "title_attachments",
  "AmuseWikiFarm::Schema::Result::TitleAttachment",
  { "foreign.attachment_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 titles

Type: many_to_many

Composing rels: L</title_attachments> -> title

=cut

__PACKAGE__->many_to_many("titles", "title_attachments", "title");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-22 14:55:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gC6yxJt4W8A9v1PNZEr5mQ

=head2 File classes

Defined C<f_class> values:

=over 4

=item image

A standard image

=item special_image

An images belonging to a special text

=item upload_pdf

A pdf. Cannot be inlined.

=back

=head3 can_be_inlined

Return false if it's a PDF, false otherwise

=cut

use Text::Amuse::Functions qw/muse_format_line muse_to_html/;
use AmuseWikiFarm::Log::Contextual;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse qw/build_full_uri/;

sub can_be_inlined {
    my $self = shift;
    if ($self->f_class eq 'upload_pdf') {
        return 0;
    }
    else {
        return 1;
    }
}

sub full_uri {
    my $self = shift;
    return build_full_uri({
                           class => 'Attachment',
                           f_class => $self->f_class,
                           uri => $self->uri,
                           site_id => $self->site_id,
                          });
}

sub thumbnail_base_path {
    my $self = shift;
    return '/uploads/' . $self->site_id . '/thumbnails/' . $self->uri;
}

sub thumbnail_uri {
    return shift->thumbnail_base_path . '.thumb.png';
}

sub small_uri {
    return shift->thumbnail_base_path . '.small.png';
}

sub large_uri {
    return shift->thumbnail_base_path . '.large.png';
}

sub alt_title {
    my $self = shift;
    $self->title_muse ? $self->title_muse : $self->uri;
}

sub edit {
    my ($self, %args) = @_;
    my %update;
    foreach my $k (qw/title_muse comment_muse/) {
        $update{$k} = defined($args{$k}) ? $args{$k} : '';
    }
    $update{title_html} = muse_format_line(html => $update{title_muse});
    $update{comment_html} = muse_to_html($update{comment_muse});
    Dlog_debug { "Updating $_" } \%update;
    $self->update(\%update);
}

sub separator { return undef }

sub path_object {
    return path(shift->f_full_path_name);
}

sub generate_thumbnails {
    my $self = shift;
    my $srcfile = $self->path_object;
    my $basename = $srcfile->basename;
    my $repo_root = $self->site->repo_root;
    die "$srcfile does not exists" unless -f $srcfile;

    my $src = "$srcfile";
    return unless $basename =~ m/\.(pdf|png|jpe?g)\z/;

    if ($src =~ m/\.\./ or
        $src !~ m/\A\Q$repo_root\E/) {
        die "$src is outside the repo root";
    }

    # see AmuseWikiFarm::Schema::ResultSet::GlobalSiteFile;
    my %dimensions = (
                      '.large.png' => '300',
                      '.small.png' => '150',
                      '.thumb.png' => '36',
                     );
    my $thumbnail_dir = path('thumbnails');
    foreach my $ext (keys %dimensions) {
        my $outfile = path($thumbnail_dir, $self->site_id, $basename . $ext);
        $outfile->parent->mkpath;
        my $out = $outfile->absolute;
        my ($w, $h) = AmuseWikiFarm::Utils::Amuse::create_thumbnail($src, $out, $dimensions{$ext});
        if ($w && $h) {
            $self->thumbnails->update_or_create({
                                                 site_id => $self->site_id,
                                                 file_name => $outfile->basename,
                                                 file_path => $out,
                                                 image_width => $w,
                                                 image_height => $h,
                                                });
        }
        else {
            log_error { "Cannot extract thumbnail from $src into $out with $dimensions{$ext}"};
        }
    }
}

sub thumbnails {
    shift->global_site_files->thumbnails;
}

sub is_audio {
    my $self = shift;
    if ($self->mime_type =~ m|^audio|) {
        return 1;
    }
    else {
        return 0;
    }
}

sub is_video {
    my $self = shift;
    if ($self->mime_type =~ m|^video|) {
        return 1;
    }
    else {
        return 0;
    }
}

sub has_thumbnails {
    return shift->f_class ne 'upload_binary';
}

__PACKAGE__->meta->make_immutable;
1;
