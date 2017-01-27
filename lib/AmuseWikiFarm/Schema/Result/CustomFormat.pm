use utf8;
package AmuseWikiFarm::Schema::Result::CustomFormat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::CustomFormat - Custom output formats, including profiles

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
  is_nullable: 1
  size: 16

=head2 format_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 format_description

  data_type: 'text'
  is_nullable: 1

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
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 16 },
  "format_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "format_description",
  { data_type => "text", is_nullable => 1 },
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

=head1 RELATIONS

=head2 bookbuilder_profiles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::BookbuilderProfile>

=cut

__PACKAGE__->has_many(
  "bookbuilder_profiles",
  "AmuseWikiFarm::Schema::Result::BookbuilderProfile",
  { "foreign.custom_formats_id" => "self.custom_formats_id" },
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
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-01-27 17:00:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2XmL+V7hOP+MhUnQUcLlqQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
