use utf8;
package AmuseWikiFarm::Schema::Result::CustomFormat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::CustomFormat - Custom output formats

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

=head1 TABLE: C<custom_formats>

=cut

__PACKAGE__->table("custom_formats");

=head1 ACCESSORS

=head2 custom_formats_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 format_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 format_description

  data_type: 'text'
  is_nullable: 1

=head2 format_alias

  data_type: 'varchar'
  is_nullable: 1
  size: 8

=head2 active

  data_type: 'smallint'
  default_value: 1
  is_nullable: 1

=head2 bb_format

  data_type: 'varchar'
  default_value: 'pdf'
  is_nullable: 0
  size: 16

=head2 bb_epub_embed_fonts

  data_type: 'smallint'
  default_value: 1
  is_nullable: 1

=head2 bb_bcor

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_beamercolortheme

  data_type: 'varchar'
  default_value: 'dove'
  is_nullable: 0
  size: 255

=head2 bb_beamertheme

  data_type: 'varchar'
  default_value: 'default'
  is_nullable: 0
  size: 255

=head2 bb_cover

  data_type: 'smallint'
  default_value: 1
  is_nullable: 1

=head2 bb_crop_marks

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_crop_papersize

  data_type: 'varchar'
  default_value: 'a4'
  is_nullable: 0
  size: 255

=head2 bb_crop_paper_height

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_crop_paper_width

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_crop_paper_thickness

  data_type: 'varchar'
  default_value: '0.10mm'
  is_nullable: 0
  size: 16

=head2 bb_division

  data_type: 'integer'
  default_value: 12
  is_nullable: 0

=head2 bb_fontsize

  data_type: 'integer'
  default_value: 10
  is_nullable: 0

=head2 bb_headings

  data_type: 'varchar'
  default_value: 0
  is_nullable: 0
  size: 255

=head2 bb_imposed

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_mainfont

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 bb_sansfont

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 bb_monofont

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 bb_nocoverpage

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_coverpage_only_if_toc

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_nofinalpage

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_notoc

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_opening

  data_type: 'varchar'
  default_value: 'any'
  is_nullable: 0
  size: 16

=head2 bb_papersize

  data_type: 'varchar'
  default_value: 'generic'
  is_nullable: 0
  size: 255

=head2 bb_paper_height

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_paper_width

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_schema

  data_type: 'varchar'
  default_value: '2up'
  is_nullable: 0
  size: 255

=head2 bb_signature

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 bb_twoside

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=head2 bb_unbranded

  data_type: 'smallint'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "custom_formats_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "format_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "format_description",
  { data_type => "text", is_nullable => 1 },
  "format_alias",
  { data_type => "varchar", is_nullable => 1, size => 8 },
  "active",
  { data_type => "smallint", default_value => 1, is_nullable => 1 },
  "bb_format",
  {
    data_type => "varchar",
    default_value => "pdf",
    is_nullable => 0,
    size => 16,
  },
  "bb_epub_embed_fonts",
  { data_type => "smallint", default_value => 1, is_nullable => 1 },
  "bb_bcor",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_beamercolortheme",
  {
    data_type => "varchar",
    default_value => "dove",
    is_nullable => 0,
    size => 255,
  },
  "bb_beamertheme",
  {
    data_type => "varchar",
    default_value => "default",
    is_nullable => 0,
    size => 255,
  },
  "bb_cover",
  { data_type => "smallint", default_value => 1, is_nullable => 1 },
  "bb_crop_marks",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_crop_papersize",
  {
    data_type => "varchar",
    default_value => "a4",
    is_nullable => 0,
    size => 255,
  },
  "bb_crop_paper_height",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_crop_paper_width",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_crop_paper_thickness",
  {
    data_type => "varchar",
    default_value => "0.10mm",
    is_nullable => 0,
    size => 16,
  },
  "bb_division",
  { data_type => "integer", default_value => 12, is_nullable => 0 },
  "bb_fontsize",
  { data_type => "integer", default_value => 10, is_nullable => 0 },
  "bb_headings",
  { data_type => "varchar", default_value => 0, is_nullable => 0, size => 255 },
  "bb_imposed",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_mainfont",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "bb_sansfont",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "bb_monofont",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "bb_nocoverpage",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_coverpage_only_if_toc",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_nofinalpage",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_notoc",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_opening",
  {
    data_type => "varchar",
    default_value => "any",
    is_nullable => 0,
    size => 16,
  },
  "bb_papersize",
  {
    data_type => "varchar",
    default_value => "generic",
    is_nullable => 0,
    size => 255,
  },
  "bb_paper_height",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_paper_width",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_schema",
  {
    data_type => "varchar",
    default_value => "2up",
    is_nullable => 0,
    size => 255,
  },
  "bb_signature",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "bb_twoside",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
  "bb_unbranded",
  { data_type => "smallint", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</custom_formats_id>

=back

=cut

__PACKAGE__->set_primary_key("custom_formats_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_format_alias_unique>

=over 4

=item * L</site_id>

=item * L</format_alias>

=back

=cut

__PACKAGE__->add_unique_constraint("site_id_format_alias_unique", ["site_id", "format_alias"]);

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-10-20 08:36:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SIYx8fO56/+N04N8PtEODA

use Try::Tiny;
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Archive::BookBuilder;
use File::Temp;
use File::Copy qw/copy/;

sub update_from_params {
    my ($self, $params) = @_;
    my $return = { error => '' };
    try {
        foreach my $meta (qw/format_description format_name/) {
            if (defined $params->{$meta}) {
                $self->$meta(delete $params->{$meta});
            }
            my $bb = $self->bookbuilder;
            $bb->import_profile_from_params(%$params);
            my $out = $bb->serialize_profile;
            foreach my $k (keys %$out) {
                my $method = 'bb_' . $k;
                $self->$method($out->{$k});
            }
        }
        $self->update if $self->is_changed;
    } catch {
        $return->{error} = $_;
        log_error { $return->{error} };
    };
    return $return;
}

sub bookbuilder {
    my ($self) = @_;
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $self->site,
                                                      is_single_file => 1,
                                                      single_file_extension => $self->extension,
                                                     );
    foreach my $accessor ($bb->profile_methods) {
        my $column = 'bb_' . $accessor;
        try {
            $bb->$accessor($self->$column);
        } catch {
            my $error = $_;
            log_warn { $column . ' => ' . $error->message };
        };
    }
    return $bb;
}

sub compile {
    my ($self, $muse, $logger) = @_;
    my $bb = $self->bookbuilder;
    log_debug { "Compiling" };
    if (my $res = $bb->compile($logger, $muse)) {
        my ($tex) = $bb->bbdir->children(qr{\.tex\z});
        if ($tex) {
            log_debug { "Copying $tex to " . $muse->filepath_for_ext($self->tex_extension) };
            $tex->copy($muse->filepath_for_ext($self->tex_extension));
        }
        if (my $alias = $self->format_alias) {
            my %permitted = (
                             pdf => 1,
                             'sl.pdf' => 1,
                             'a4.pdf' => 1,
                             'lt.pdf' => 1,
                            );
            if ($permitted{$alias}) {
                copy ($muse->filepath_for_ext($self->extension),
                      $muse->filepath_for_ext($alias))
                  or die "Couldn't copy "
                  . $muse->filepath_for_ext($self->extension)
                  . " to "
                  . $muse->filepath_for_ext($self->alias) . "$!";
            }
            else {
                die "$alias is not a permitted alias!";
            }
        }
        return $res;
    }
    else {
        return;
    }
}

sub needs_compile {
    my ($self, $muse) = @_;
    my $src = $muse->filepath_for_ext('muse');
    log_debug { "checking $src" };
    if (-f $src) {
        my $expected = $muse->filepath_for_ext($self->extension);
        log_debug { "$expected exist" };
        if (-f $expected) {
            log_debug { "$src and $expected exist" };
            if ((stat($expected))[9] >= (stat($src))[9]) {
                log_debug { "$expected and $src exist" .  (stat($expected))[9] . '>=' . (stat($src))[9] };
                return 0;
            }
        }
    }
    return 1;
}

sub is_epub {
    return shift->bb_format eq 'epub';
}

sub is_pdf {
    return shift->bb_format eq 'pdf';
}

sub tex_extension {
    my $self = shift;
    my $code = $self->custom_formats_id;
    return "c${code}.tex";
}

sub extension {
    my $self = shift;
    my $code = $self->custom_formats_id;
    my $format = $self->bb_format;
    if ($format eq 'pdf' or $format eq 'epub') {
        return "c${code}.${format}";
    }
    else {
        die "format $format is invalid";
    }
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
