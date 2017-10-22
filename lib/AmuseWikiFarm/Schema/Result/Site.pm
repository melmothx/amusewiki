use utf8;
package AmuseWikiFarm::Schema::Result::Site;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Site - Site definitions

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

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 mode

  data_type: 'varchar'
  default_value: 'private'
  is_nullable: 0
  size: 16

=head2 locale

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 magic_question

  data_type: 'varchar'
  default_value: '12 + 4 ='
  is_nullable: 0
  size: 255

=head2 magic_answer

  data_type: 'varchar'
  default_value: 16
  is_nullable: 0
  size: 255

=head2 fixed_category_list

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 sitename

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 siteslogan

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 theme

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 logo

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 mail_notify

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 mail_from

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 canonical

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 secure_site

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 secure_site_only

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 sitegroup

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 cgit_integration

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 ssl_key

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ssl_cert

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ssl_ca_cert

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 ssl_chained_cert

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 acme_certificate

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 multilanguage

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 blog_style

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 bb_page_limit

  data_type: 'integer'
  default_value: 1000
  is_nullable: 0

=head2 tex

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 pdf

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 a4_pdf

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 lt_pdf

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 sl_pdf

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 html

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 bare_html

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 epub

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 zip

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 ttdir

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 papersize

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 division

  data_type: 'integer'
  default_value: 12
  is_nullable: 0

=head2 bcor

  data_type: 'varchar'
  default_value: '0mm'
  is_nullable: 0
  size: 16

=head2 fontsize

  data_type: 'integer'
  default_value: 10
  is_nullable: 0

=head2 mainfont

  data_type: 'varchar'
  default_value: 'CMU Serif'
  is_nullable: 0
  size: 255

=head2 sansfont

  data_type: 'varchar'
  default_value: 'CMU Sans Serif'
  is_nullable: 0
  size: 255

=head2 monofont

  data_type: 'varchar'
  default_value: 'CMU Typewriter Text'
  is_nullable: 0
  size: 255

=head2 beamertheme

  data_type: 'varchar'
  default_value: 'default'
  is_nullable: 0
  size: 255

=head2 beamercolortheme

  data_type: 'varchar'
  default_value: 'dove'
  is_nullable: 0
  size: 255

=head2 nocoverpage

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 logo_with_sitename

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 opening

  data_type: 'varchar'
  default_value: 'any'
  is_nullable: 0
  size: 16

=head2 twoside

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 last_updated

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "mode",
  {
    data_type => "varchar",
    default_value => "private",
    is_nullable => 0,
    size => 16,
  },
  "locale",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "magic_question",
  {
    data_type => "varchar",
    default_value => "12 + 4 =",
    is_nullable => 0,
    size => 255,
  },
  "magic_answer",
  { data_type => "varchar", default_value => 16, is_nullable => 0, size => 255 },
  "fixed_category_list",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "sitename",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "siteslogan",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "theme",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "logo",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "mail_notify",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "mail_from",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "canonical",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "secure_site",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "secure_site_only",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "sitegroup",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "cgit_integration",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "ssl_key",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ssl_cert",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ssl_ca_cert",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "ssl_chained_cert",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "acme_certificate",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "multilanguage",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "blog_style",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "bb_page_limit",
  { data_type => "integer", default_value => 1000, is_nullable => 0 },
  "tex",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "pdf",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "a4_pdf",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "lt_pdf",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "sl_pdf",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "html",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "bare_html",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "epub",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "zip",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "ttdir",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "papersize",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "division",
  { data_type => "integer", default_value => 12, is_nullable => 0 },
  "bcor",
  {
    data_type => "varchar",
    default_value => "0mm",
    is_nullable => 0,
    size => 16,
  },
  "fontsize",
  { data_type => "integer", default_value => 10, is_nullable => 0 },
  "mainfont",
  {
    data_type => "varchar",
    default_value => "CMU Serif",
    is_nullable => 0,
    size => 255,
  },
  "sansfont",
  {
    data_type => "varchar",
    default_value => "CMU Sans Serif",
    is_nullable => 0,
    size => 255,
  },
  "monofont",
  {
    data_type => "varchar",
    default_value => "CMU Typewriter Text",
    is_nullable => 0,
    size => 255,
  },
  "beamertheme",
  {
    data_type => "varchar",
    default_value => "default",
    is_nullable => 0,
    size => 255,
  },
  "beamercolortheme",
  {
    data_type => "varchar",
    default_value => "dove",
    is_nullable => 0,
    size => 255,
  },
  "nocoverpage",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "logo_with_sitename",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "opening",
  {
    data_type => "varchar",
    default_value => "any",
    is_nullable => 0,
    size => 16,
  },
  "twoside",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "last_updated",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<canonical_unique>

=over 4

=item * L</canonical>

=back

=cut

__PACKAGE__->add_unique_constraint("canonical_unique", ["canonical"]);

=head1 RELATIONS

=head2 attachments

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Attachment>

=cut

__PACKAGE__->has_many(
  "attachments",
  "AmuseWikiFarm::Schema::Result::Attachment",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bookbuilder_sessions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::BookbuilderSession>

=cut

__PACKAGE__->has_many(
  "bookbuilder_sessions",
  "AmuseWikiFarm::Schema::Result::BookbuilderSession",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 bulk_jobs

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::BulkJob>

=cut

__PACKAGE__->has_many(
  "bulk_jobs",
  "AmuseWikiFarm::Schema::Result::BulkJob",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 categories

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Category>

=cut

__PACKAGE__->has_many(
  "categories",
  "AmuseWikiFarm::Schema::Result::Category",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 custom_formats

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::CustomFormat>

=cut

__PACKAGE__->has_many(
  "custom_formats",
  "AmuseWikiFarm::Schema::Result::CustomFormat",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 jobs

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Job>

=cut

__PACKAGE__->has_many(
  "jobs",
  "AmuseWikiFarm::Schema::Result::Job",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 legacy_links

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::LegacyLink>

=cut

__PACKAGE__->has_many(
  "legacy_links",
  "AmuseWikiFarm::Schema::Result::LegacyLink",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 monthly_archives

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::MonthlyArchive>

=cut

__PACKAGE__->has_many(
  "monthly_archives",
  "AmuseWikiFarm::Schema::Result::MonthlyArchive",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 redirections

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Redirection>

=cut

__PACKAGE__->has_many(
  "redirections",
  "AmuseWikiFarm::Schema::Result::Redirection",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 revisions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Revision>

=cut

__PACKAGE__->has_many(
  "revisions",
  "AmuseWikiFarm::Schema::Result::Revision",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site_links

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::SiteLink>

=cut

__PACKAGE__->has_many(
  "site_links",
  "AmuseWikiFarm::Schema::Result::SiteLink",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 site_options

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::SiteOption>

=cut

__PACKAGE__->has_many(
  "site_options",
  "AmuseWikiFarm::Schema::Result::SiteOption",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 text_internal_links

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TextInternalLink>

=cut

__PACKAGE__->has_many(
  "text_internal_links",
  "AmuseWikiFarm::Schema::Result::TextInternalLink",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title_stats

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleStat>

=cut

__PACKAGE__->has_many(
  "title_stats",
  "AmuseWikiFarm::Schema::Result::TitleStat",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->has_many(
  "titles",
  "AmuseWikiFarm::Schema::Result::Title",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_sites

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::UserSite>

=cut

__PACKAGE__->has_many(
  "user_sites",
  "AmuseWikiFarm::Schema::Result::UserSite",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 vhosts

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Vhost>

=cut

__PACKAGE__->has_many(
  "vhosts",
  "AmuseWikiFarm::Schema::Result::Vhost",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</user_sites> -> user

=cut

__PACKAGE__->many_to_many("users", "user_sites", "user");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-07-05 11:50:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IRDckgBXqdvMO9G6uWyUjQ

=head2 other_sites

Other sites with the same sitegroup id.

=cut

__PACKAGE__->has_many(
    other_sites => "AmuseWikiFarm::Schema::Result::Site",
    sub {
        my $args = shift;
        return {
            "$args->{foreign_alias}.sitegroup" => { -ident => "$args->{self_alias}.sitegroup",
                                                    '!=' => '' },
            "$args->{foreign_alias}.id" => { "!=" => { -ident => "$args->{self_alias}.id" } },
        };
    },
    { cascade_copy => 0, cascade_delete => 0 },
   );

use File::Spec;
use Cwd;
use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_file_info
                                   muse_filepath_is_valid
                                   cover_filename_is_valid
                                   muse_naming_algo/;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse html_file_to_muse/;
use Text::Amuse::Compile;
use Date::Parse;
use DateTime;
use File::Copy qw/copy/;
use AmuseWikiFarm::Archive::Xapian;
use Unicode::Collate::Locale;
use File::Find;
use Data::Dumper::Concise;
use AmuseWikiFarm::Archive::BookBuilder;
use Text::Amuse::Compile::Utils ();
use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::CgitSetup;
use AmuseWikiFarm::Utils::LexiconMigration;
use Regexp::Common qw/net/;
use Path::Tiny ();
use AmuseWikiFarm::Utils::Paths ();
use Try::Tiny;

=head2 repo_root_rel

The location of the repository. It's hardcoded as 'repo/<id>'
according to the system path separator. You have no reason to change
this.

=head2 repo_root

The absolute location of the repository. Keep in mind that the
absolute location is inferred with C<getcwd()> + C<repo_name>, so it's
not safe to change directory and call this method.

You can provide an optional argument to get the base (absolute or
relative to the CWD).

=cut

sub repo_root_rel {
    my $self = shift;
    return File::Spec->catdir(repo => $self->id);
}

sub repo_root {
    my ($self, $base) = @_;
    unless (defined $base) {
        $base = '';
    }
    return File::Spec->rel2abs($self->repo_root_rel, $base);
}

=head2 compile_options

Options to feed the Text::Amuse::Compile object.

=cut

sub valid_ttdir {
    my $self = shift;
    if (my $ttdir = $self->ttdir) {
        # sane names only please
        if ($ttdir =~ m/\A[0-9a-zA-Z][0-9a-zA-Z_-]*[0-9a-zA-Z]\z/) {
            my $full_path = File::Spec->catdir($self->repo_root, $ttdir);
            if (-d $full_path) {
                return $full_path;
            }
        }
    }
    return;
}


sub compile_options {
    my $self = shift;
    my %opts = (
                tex => 1,
                html => 1,
                bare_html => 1,
                epub => 1,
                zip => 1,
               );
    if ($self->use_luatex) {
        $opts{luatex} = 1;
    }
    $opts{epub_embed_fonts} = 0;
    $opts{fontspec} = $self->fontspec_file;

    if (my $dir = $self->valid_ttdir) {
        $opts{ttdir} = $dir;
    }

    # passing nocoverpage, as we used to, would kill the coverpage
    # globally. If you really want that, you need a custom format.
    if ($self->nocoverpage) {
        $opts{coverpage_only_if_toc} = 1;
    }

    foreach my $ext (qw/siteslogan logo
                        sitename opening
                        papersize division fontsize
                        bcor mainfont sansfont monofont
                        beamertheme beamercolortheme
                        twoside/) {
        $opts{extra}{$ext} = $self->$ext;
    }
    # if the logo has the sitename in it, skip it.
    if ($self->logo_with_sitename) {
        $opts{extra}{sitename} = '';
    }
    $opts{extra}{site} = $self->canonical;
    Dlog_debug { "options are $_" } (\%opts);
    return %opts;
}

sub formats_definitions {
    my ($self, %opts) = @_;
    my @all = ({
                code => 'epub',
                ext => '.epub',
                icon => 'fa-tablet',
                desc => 'EPUB (for mobile devices)',
                oldid => "downloadepub",
               },
               {
                code => 'html',
                ext => '.html',
                icon => 'fa-print',
                desc => 'Standalone HTML (printer-friendly)',
                oldid => "downloadhtml",
               },
               {
                code => 'tex',
                ext => '.tex',
                icon => 'fa-file-code-o',
                desc => 'XeLaTeX source',
                oldid => "downloadtex",
               },
               {
                code => 'muse',
                ext => '.muse',
                icon => 'fa-file-text-o',
                desc => 'plain text source',
                oldid => "downloadsrc",
               },
               {
                code => 'zip',
                ext => '.zip',
                icon => 'fa-file-archive-o',
                desc => 'Source files with attachments',
                oldid => "downloadzip",
               }
              );
    my %legacy_ids = (
                      pdf => 'pdfgeneric',
                      'a4.pdf' => 'pdfa4imp',
                      'lt.pdf' => 'letterimp',
                      'sl.pdf' => 'downloadslides',
                     );
    my @out;
    foreach my $custom ($self->custom_formats->active_only->all) {
        my $icon;
        if ($custom->is_epub) {
            $icon = 'fa-tablet';
        }
        elsif ($custom->is_imposed_pdf) {
            $icon = 'fa-columns fa-flip-vertical';
        }
        elsif ($custom->is_slides) {
            $icon = 'fa-file-powerpoint-o';
        }
        else {
            $icon = 'fa-file-pdf-o'
        }
        my $old_id;
        if (my $alias = $custom->format_alias) {
            $old_id = $legacy_ids{$alias};
        }
        my $extension = $custom->format_alias || $custom->extension;
        push @out, {
                    code => $extension,
                    ext => '.' . $extension,
                    icon => $icon,
                    desc => $custom->format_name,
                    oldid => $old_id,
                    is_slides => $custom->is_slides,
                   };
    }
    push @out, @all;
    if ($opts{localize}) {
        log_debug { "Localizing descriptions" };
        my $loc = $self->localizer;
        foreach my $i (@out) {
            $i->{desc} = $loc->loc_html($i->{desc});
        }
    }
    return \@out;
}

sub bb_values {
    my $self = shift;
    # here the problem is that there is no 1:1 mapping, which kind of
    # sucks, but hey.
    my %out;
    my %map = (division => 0,
               bcor => 0,
               fontsize => 0,
               mainfont => 0,
               sansfont => 0,
               monofont => 0,
               beamertheme => 0,
               beamercolortheme => 0,
               nocoverpage => 'coverpage_only_if_toc',
               twoside => 0,
              );
    foreach my $method (sort keys %map) {
        my $target = $map{$method} || $method;
        # special shitty case.
        if ($method eq 'bcor') {
            if ($self->bcor =~ m/0?([1-9][0-9]*)(mm)?/) {
                $out{$target} = $1;
            }
        }
        else {
            $out{$target} = $self->$method;
        }
    }
    my $valid;
    try {
        # validate
        if (my $bb = AmuseWikiFarm::Archive::BookBuilder->new(%out)) {
            $valid = 1;
        }
    } catch {
        my $err = $_;
        # scream, so we fix it
        log_error { "$err validating $_" } \%out;
    };
    if ($valid) {
        return %out;
    }
    else {
        return;
    }
}

sub check_and_update_custom_formats {
    my $self = shift;
    my %formats = (
                   pdf => {
                           initial => {
                                       format_alias => 'pdf',
                                       format_name => 'plain PDF', # loc('plain PDF')
                                       format_priority => 1,
                                       format_description => 'Standard',
                                      },
                           fields => {
                                      bb_format => 'pdf',
                                      bb_imposed => 0,
                                     },
                          },
                   a4_pdf => {
                              initial => {
                                          format_alias => 'a4.pdf',
                                          format_name => 'A4 imposed PDF', # loc('A4 imposed PDF')
                                          format_priority => 2,
                                          bb_signature_2up => '40-80',
                                          format_description => 'Standard',
                                         },
                              fields => {
                                         bb_format => 'pdf',
                                         bb_imposed => 1,
                                         bb_papersize => 'a5',
                                         bb_schema => '2up',
                                         bb_cover => 1,
                                        },
                             },
                   lt_pdf => {
                              initial => {
                                          format_alias => 'lt.pdf',
                                          format_name => 'Letter imposed PDF', # loc('Letter imposed PDF')
                                          format_priority => 3,
                                          bb_signature_2up => '40-80',
                                          format_description => 'Standard',
                                          },
                              fields => {
                                         bb_format => 'pdf',
                                         bb_imposed => 1,
                                         bb_papersize => '5.5in:8.5in',
                                         bb_schema => '2up',
                                         bb_cover => 1,
                                        },
                             },
                   sl_pdf => {
                              initial => {
                                          format_alias => 'sl.pdf',
                                          format_name => 'Slides (PDF)', # loc('Slides (PDF)'),
                                          format_priority => 4,
                                          format_description => 'Standard',
                                          },
                              fields => {
                                         bb_format => 'slides',
                                        },
                             },
                  );
    my $guard = $self->result_source->schema->txn_scope_guard;
    foreach my $method (sort keys %formats) {
        my $alias = $formats{$method}{initial}{format_alias} or die;

        my $cf = $self->custom_formats->find({ format_alias => $alias });
        unless ($cf) {
            $cf = $self->custom_formats->create($formats{$method}{initial});
            # import the common stuff from the site
            $cf->sync_from_site;
        }
        die "Shouldn't happen" unless $cf;
        # sync the inactive status from the site. This is the other
        # way around than $cf->sync_site_format
        $cf->active($self->$method);
        $cf->update($formats{$method}{fields});
    }
    $guard->commit;
}


sub known_langs {
    my $self = shift;
    return {
            ru => 'Русский',
            sr => 'Srpski',
            hr => 'Hrvatski',
            mk => 'Македонски',
            fi => 'Suomi',
            it => 'Italiano',
            es => 'Español',
            en => 'English',
            fr => 'Français',
            nl => 'Nederlands',
            de => 'Deutsch',
            sq => 'Shqip',
            sv => 'Svenska',
            pl => 'Polski',
            pt => 'Português',
            da => 'Dansk',
           };
}

sub known_langs_as_string {
    my $self = shift;
    my $langs = $self->known_langs;
    return join(' ', sort keys %$langs);
}

sub path_for_specials {
    my $self = shift;
    my $target = File::Spec->catdir($self->repo_root, 'specials');
    mkdir $target unless -d $target;
    return $target;
}

sub path_for_uploads {
    my $self = shift;
    my $target = File::Spec->catdir($self->repo_root, 'uploads');
    mkdir $target unless -d $target;
    return $target;
}

sub path_for_file {
    my ($self, $uri) = @_;
    return unless $uri;
    my $pieces = muse_get_full_path($uri);
    return unless $pieces && @$pieces && @$pieces == 3;

    # add the path piece by piece
    my $target_dir = File::Spec->catdir($self->repo_root, $pieces->[0]);
    unless (-d $target_dir) {
        mkdir $target_dir or die $!;
    }
    $target_dir = File::Spec->catdir($self->repo_root,
                                     $pieces->[0], $pieces->[1]);
    unless (-d $target_dir) {
        mkdir $target_dir or die $!;
    }
    return $target_dir;
}

sub path_for_site_files {
    my $self = shift;
    return File::Spec->catdir($self->repo_root, 'site_files');
}

sub has_site_file {
    my ($self, $file) = @_;
    return unless $file && $file =~ m/^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.[a-z0-9]+$/s;
    my $path = File::Spec->catfile($self->path_for_site_files, $file);
    if (-f $path) {
        return $path;
    }
    else {
        return;
    }
}

sub fontspec_file {
    my $self = shift;
    my $filename = 'fontspec.json';
    if (my $file = $self->has_site_file($filename)) {
        return $file;
    }
    # search the current dir for fontspec.json
    elsif (-f $filename) {
        return File::Spec->rel2abs($filename);
    }
    else {
        return undef;
    }
}


=head2 repo_is_under_git

Return true if the site repo is kept under git.

=cut

has repo_is_under_git => (is => 'ro',
                          isa => 'Bool',
                          lazy => 1,
                          builder => '_build_repo_is_under_git');

sub _build_repo_is_under_git {
    my $self = shift;
    return -d File::Spec->catdir($self->repo_root, '.git');
}

=head1 Site modes

To check the site mode, you should use these methods, instead of
looking at C<mode>.

The filtered actions boil down to editing and publishing, where
editing is also the creation of new texts.

=cut

sub available_modes {
    return {
            modwiki => 1,
            openwiki => 1,
            blog => 1,
            private => 1,
           };
}


sub human_can_edit {
    my $self = shift;
    my $mode = $self->mode;
    if ($mode eq 'modwiki' or
        $mode eq 'openwiki') {
        return 1;
    }
    else {
        return;
    }
}

sub human_can_publish {
    my $self = shift;
    my $mode = $self->mode;
    if ($mode eq 'openwiki') {
        return 1;
    }
    else {
        return;
    }
}

sub is_private {
    my $self = shift;
    my $mode = $self->mode;
    if ($mode eq 'private') {
        return 1;
    }
    else {
        return;
    }
}

=head1 Create new texts

=head2 staging_dirname

The relative path to the staging directory. Hardcoded for now as 'staging'.

=head2 staging_dir

The absolute path to the staging directory, concatenating the
C<staging_dirname> and the current directory.

TODO: use a setting instead of the getcwd.

=cut

sub staging_dirname {
    return 'staging';
}

sub staging_dir {
    my $self = shift;
    return File::Spec->catdir(getcwd(), $self->staging_dirname);
}

=head2 create_new_text(\%params, $f_class)

Using the parameters passed, create a new text and return its revision
object or undef it couldn't be created.

The second argument B<must> be C<text> or C<special>.

Always return two values: the first is the revision object, the second
is the redirection.

If the revision could not be created, return undef as the first
element and the error in the second.

=cut


sub create_new_text {
    my ($self, $params, $f_class) = @_;
    die "Missing params"  unless $params;
    die "Missing f_class" unless $f_class;
    die "Wrong f_class $f_class"
      unless ($f_class eq 'text' or $f_class eq 'special');
    # assert that the directory where to put the files exists
    my $staging_dir = $self->staging_dir;
    unless (-d $staging_dir) {
        mkdir $self->staging_dir or die "Couldn't create $staging_dir $!";
    }
    # URI generation
    my $author = $params->{author} // "";
    my $title  = $params->{title}  // "";
    my $uri;
    if ($params->{uri}) {
        $uri = muse_naming_algo($params->{uri});
        # replace the params with our clean form
    }
    elsif ($title =~ m/\w/) {
        my $string = "$author $title";
        if ($self->multilanguage && $params->{lang}) {
            $string = substr($string, 0, 90) . ' ' . $params->{lang};
        }
        $uri = muse_naming_algo($string);
    }
    unless ($uri) {
        # loc("Couldn't automatically generate the URI!");
        return undef, "Couldn't automatically generate the URI!";
    }

    # and store it in the params
    $params->{uri} = $uri;

    if ($self->titles->find({ uri => $uri, f_class => $f_class })) {
        # loc("Such an URI already exists");
        return undef, "Such an URI already exists";
    }
    return $self->import_text_from_html_params($params, $f_class);
}

=head2 import_text_from_html_params

HTML => muse conversion

=cut

sub import_text_from_html_params {
    my ($self, $params, $f_class) = @_;
    die "Missing params"  unless $params;
    die "Missing f_class" unless $f_class;
    my $uri = $params->{uri};
    die "uri not set!" unless $uri;

    # the first thing we do is to assing a path and create a revision in the db
    my $pubdate = str2time($params->{pubdate}) || time();
    my $pubdt = DateTime->from_epoch(epoch => $pubdate);
    $params->{pubdate} = $pubdt->iso8601;

    # documented in Result::Title
    my $bogus = {
                 uri => $uri,
                 pubdate => $pubdt,
                 f_suffix => '.muse',
                 status => 'editing',
                 f_class => $f_class,
                 # dummy as well, 40 years in the past
                 f_timestamp => DateTime->from_epoch(epoch => 1),
                };

    foreach my $f (qw/f_path f_archive_rel_path
                      f_full_path_name f_name/) {
        $bogus->{$f} = '';
    }


    my $body;
    my $error;
    if ($params->{fileupload}) {
        if (-f $params->{fileupload} && -T $params->{fileupload}) {
            $body = eval { html_file_to_muse($params->{fileupload}) };
            if ($@) {
                log_error { "error while converting file upload: " . $@ };
                # loc('Error converting the upload file. Is it an HTML file?');
                $error = "Error converting the upload file. Is it an HTML file?";
            }
        }
        else {
            log_error { $params->{fileupload} . " is not a text file!" };
            # loc('The file uploaded is not an HTML file!');
            $error = "The file uploaded is not an HTML file!";
        }
    }
    else {
        $params->{textbody} //= "\n";
        $params->{textbody} =~ s/\r//g;
        $body = eval { html_to_muse($params->{textbody}) };
        if ($@) {
            log_error { "error while converting HTML: " . $@ };
            # loc('Error while converting the HTML. Sorry.');
            $error = "Error while converting the HTML. Sorry.";
        }
    }
    if ($error) {
        return undef, $error;
    }

    my $guard = $self->result_source->schema->txn_scope_guard;
    # title->can_spawn_revision will return false, so we have to force
    my $revision = $self->titles->create($bogus)->new_revision('force');

    # save a copy of the html request
    my $html_copy = $revision->original_html;
    if (defined $body) {
        if ($params->{fileupload}) {
            copy ($params->{fileupload}, $html_copy) or die $!;
        }
        else {
            open (my $fhh, '>:encoding(utf-8)', $html_copy)
              or die "Couldn't open $html_copy $!";
            print $fhh $params->{textbody};
            print $fhh "\n";
            close $fhh or die $!;
        }
    }

    my $file = $revision->f_full_path_name;
    die "full path was not set!" unless $file;
    # populate the file with the parameters
    open (my $fh, '>:encoding(utf-8)', $file) or die "Couldn't open $file $!";

    foreach my $directive (qw/title subtitle author LISTtitle SORTauthors
                              SORTtopics date uid cat
                              slides
                              source lang pubdate/) {

        $self->_add_directive($fh, $directive, $params->{$directive});
    }
    # add the notes
    foreach my $field (qw/notes teaser/) {
        $self->_add_directive($fh, $field => html_to_muse($params->{$field}));
    }

    # separator
    print $fh "\n";

    if (defined $body) {
        print $fh $body;
    }
    print $fh "\n\n";
    close $fh or die $!;
    # save a copy as the starting file
    # see "new_revision" below
    die $revision->starting_file . ' already present'
      if -f $revision->starting_file;;
    copy($file, $revision->starting_file) or die $!;
    $guard->commit;
    return $revision;
}

sub _add_directive {
    my ($self, $fh, $directive, $text) = @_;
    die unless $fh && $directive;
    return unless defined $text;
    # usual washing
    $text =~ s/\r*\n/ /gs; # it's a directive, no \n
    # leading and trailing spaces
    $text =~ s/^\s*//s;
    $text =~ s/\s+$//s;
    $text =~ s/  +/ /gs; # pack the whitespaces
    return unless length($text);
    print $fh '#' . $directive . ' ' . $text . "\n";
}

=head2 xapian

Return a L<AmuseWikiFarm::Archive::Xapian> object

=cut

sub xapian {
    my $self = shift;
    return AmuseWikiFarm::Archive::Xapian->new(
                                               code => $self->id,
                                               page => $self->pagination_size_search,
                                               locale => $self->locale,
                                               # disable stemming for search on multilang environment
                                               stem_search => !$self->multilanguage,
                                               index_deferred => $self->show_preview_when_deferred,
                                              );
}

=head2 collation_index

Update the C<sorting_pos> field of each text and category based on the
collation for the current locale.

Collation on the fly would have been too slow, or would depend on the
(possibly crappy) collation of the database engine, if any.

Return the number of updates (both titles and categories);

=cut

sub collation_index {
    my $self = shift;
    my $collator = Unicode::Collate::Locale->new(locale => $self->locale);
    my $changes = 0;
    my $ttime = time();
    my @texts = sort {
        # warn $a->id . ' <=>  ' . $b->id;
        $collator->cmp($a->list_title, $b->list_title)
    } $self->titles->search(undef, { order_by => 'sorting_pos',
                                     columns => [qw/id sorting_pos list_title/] })->all;

    log_debug { "Sorting texts done in " . (time() - $ttime) . " seconds" };
    $ttime = time();

    # at least on sqlite, wrapping in a transaction drammatically
    # speeds things up because it doesn't hit the disk
    my $guard = $self->result_source->schema->txn_scope_guard;

    my $i = 1;
    foreach my $title (@texts) {
        if ($title->sorting_pos != $i) {
            $title->update({ sorting_pos => $i });
            $changes++;
        }
        $i++;
    }
    log_debug { "Update texts done in " . (time() - $ttime) . " seconds" };
    $ttime = time();

    # and then sort the categories
    my @categories = sort {
        # warn $a->id . ' <=> ' . $b->id;
        $collator->cmp($a->name, $b->name)
    } $self->categories->search(undef, { order_by => 'sorting_pos',
                                         columns => [qw/id sorting_pos name/] })->all;

    log_debug { "Sorting categories done in " . (time() - $ttime) . " seconds" };
    $ttime = time();

    $i = 1;
    foreach my $cat (@categories) {
        if ($cat->sorting_pos != $i) {
            $cat->update({ sorting_pos => $i });
            $changes++;
        }
        $i++;
    }

    # close the transaction
    $guard->commit;

    log_debug { "Update categories done in " . (time() - $ttime) . " seconds" };
    return $changes;
}

=head2 index_file($path_to_file)

Add the file to the DB and Xapian databases, first parsing it with
C<muse_info_file> from L<AmuseWikiFarm::Utils::Amuse>.

=head2 compile_and_index_files(\@abs_paths_to_files, $logger)

Same as above, but before proceeding, compile it if it's a muse file
and it's outdated.

=cut

sub get_compiler {
    my ($self, $logger) = @_;
    my $compiler = Text::Amuse::Compile->new($self->compile_options);
    if ($logger) {
        $compiler->logger($logger);
    }
    return $compiler;
}

sub compile_and_index_files {
    my ($self, $files, $logger) = @_;
    $logger ||= sub { warn $_[0] };
    my $compiler = $self->get_compiler($logger);
    my (@active_cfs, @inactive_cfs);
    foreach my $cf ($self->custom_formats) {
        if ($cf->active) {
            push @active_cfs, $cf;
        }
        else {
            push @inactive_cfs, $cf;
        }
    }
    foreach my $f (@$files) {
        my $file;
        if (ref($f)) {
            $file = $f->f_full_path_name;
        }
        # check if it's in place
        elsif (-f $f) {
            $file = File::Spec->rel2abs($f);
        }
        else {
            $file = File::Spec->rel2abs($f, $self->repo_root);
        }
        unless (-f $file) {
            die "File $file does not exists\n";
        }
        my $relpath = File::Spec->abs2rel($file, $self->repo_root);
        unless (muse_filepath_is_valid($relpath)) {
            die "$relpath doesn't appear a valid path!";
        }
        if ($file =~ m/\.muse$/) {
            # ensure that we properly migrated the PDFS to CF
            foreach my $cf (@active_cfs) {
                $cf->save_canonical_from_aliased_file($file);
            }
            # compile
            $compiler->compile($file) if $compiler->file_needs_compilation($file);
        }
        if (my $indexed = $self->index_file($file, $logger)) {
            if ($indexed->isa('AmuseWikiFarm::Schema::Result::Title')) {
                foreach my $cf (@inactive_cfs) {
                    $logger->("Removing inactive format " . $cf->format_name . "\n");
                    $cf->remove_stale_files($indexed);
                }
                foreach my $cf (@active_cfs) {
                    # the standard compilation nuked the standar formats, so we
                    # have to restore them, preserving the TS. Then we
                    # will rebuild them in the next job.
                    $cf->install_aliased_file($indexed);
                    if ($cf->needs_compile($indexed)) {
                        $logger->("Scheduled generation of " . $cf->format_name . "\n");
                        $self->jobs->build_custom_format_add({
                                                              id => $indexed->id,
                                                              cf => $cf->custom_formats_id,
                                                             });
                    }
                }
            }
        }
    }
    $logger->("Updating title and category sorting\n");
    my $time = time();
    my $changed = $self->collation_index;
    $logger->("Updated $changed records in " . (time() - $time) . " seconds\n");
    $self->generate_static_indexes($logger);
    my $now = DateTime->now;
    $self->update({ last_updated => $now })
}

sub generate_static_indexes {
    my ($self, $logger) = @_;
    $logger ||= sub { return };
    if ($self->jobs->pending->build_static_indexes_jobs->count) {
        $logger->("Generation of static indexes already scheduled\n");
    }
    else {
        $self->jobs->build_static_indexes_add;
        $logger->("Scheduled static indexes generation\n");
    }
}

sub index_file {
    my ($self, $file, $logger) = @_;
    unless ($logger) {
        $logger = sub { warn join(" ", @_) };
    }
    unless ($file && -f $file) {
        $file ||= '<empty>';
        $logger->("File $file does not exist\n");
        return;
    }

    my $details = muse_file_info($file, $self->repo_root);
    # unparsable
    return unless $details;

    my $class  = $details->{f_class};
    die "Missing class!" unless $class;

    my %handled = (
                   image => 1,
                   upload_pdf => 1,
                   special => 1,
                   special_image => 1,
                   text => 1,
                  );

    die "Unknown class $class" unless $handled{$class};

    if ($class eq 'upload_pdf' or
        $class eq 'image' or
        $class eq 'special_image') {
        $logger->("Inserting data for attachment $file\n");
        return $self->attachments->update_or_create($details);
    }

    # handle specials and texts

    # ready to store into titles?

    my $guard = $self->result_source->schema->txn_scope_guard;

    # by default text are published, unless the file info returns something else
    # and if it's an update we have to reset it.
    my %insertion = (deleted => '');
    # lower case the keys


    my $fields = $self->title_fields;
    foreach my $col (keys %$details) {
        my $db_col = lc($col);
        if (exists $fields->{$db_col}) {
            $insertion{$db_col} = delete $details->{$col};
        }
    }

    delete $details->{coverwidth};
    $insertion{cover} = cover_filename_is_valid($insertion{cover});

    # this is needed because we insert it from title, and DBIC can't
    # infer the site_id from there (even if it should, but hey).
    my @parsed_cats;
    if (my $cats_from_title = delete $details->{parsed_categories}) {
        my %cat_hash;
        foreach my $cat (@$cats_from_title) {
            # help dbic to cope with this
            $cat->{site_id} = $self->id;
            # check if there is an alias
            if (my $alias = $self->redirections->find({
                                                       uri => $cat->{uri},
                                                       type => $cat->{type},
                                                      })) {

                # check if the alias points to something
                if (my $acat = $self->categories->find({
                                                        uri => $alias->redirect,
                                                        type => $alias->type,
                                                       })) {
                    # insert that instead
                    $logger->("Alias for $cat->{name} found, using "
                              . $acat->name . " instead\n");
                    foreach my $m (qw/name uri type/) {
                        $cat->{$m} = $acat->$m;
                    }
                }
                else {
                    $logger->(sprintf("Alias %s defined, but no %s found in %s\n",
                                      $alias->uri, $alias->redirect,
                                      $alias->type));
                }
            }
            # here we have to check duplicated categories after the
            # aliasing, which would trigger an exception.
            my $cat_hashed = $cat->{type} . '/' . $cat->{uri};
            if ($cat_hash{$cat_hashed}) {
                $logger->("Duplicated $cat_hashed\n");
            }
            else {
                $cat_hash{$cat_hashed} = 1;
                push @parsed_cats, $cat;
            }
        }
    }
    if (%$details) {
        $logger->("Custom directives: " . join(", ", %$details) . "\n");
    }
    $logger->("Inserting data for $file\n");

    my $title = $self->titles->update_or_create(\%insertion)->discard_changes;

    # handle redirections
    if (my $deletion_msg = $title->deleted) {
        if ($deletion_msg =~ m/^\s*redirect\:?\s+([a-z0-9-]+)\s*$/i) {
            my $target = $1;
            $logger->("Setting redirection to $target\n");
            $self->redirections->update_or_create(
                                                  uri => $title->uri,
                                                  type => $title->f_class,
                                                  redirect => $target,
                                                 );
        }
    }
    elsif (my $redir = $self->redirections->find({
                                                  uri => $title->uri,
                                                  type => $title->f_class,
                                                 })) {
        $logger->("Removing existing redirection to "
                  . $redir->full_dest_uri . "\n");
        $redir->delete;
    }

    # pick the old categories.
    my @old_cats_ids;
    foreach my $old_cat ($title->categories) {
        push @old_cats_ids, $old_cat->id;
    }

    my $name = $title->uri;
    $title->update_text_status($logger);

    # before setting them, update or create. This way, the latest
    # update will overwrite older one in case an error which maps to
    # the same uri is spotted. For example, "pinco pallino" => "Pinco
    # Pallino", without being stuck with the lower case. This of
    # course is also a bit of performance penalty but i guess it's
    # barely misurable on a normal run.
    foreach my $category (@parsed_cats) {
        $self->categories->update_or_create($category);
    }
    $title->set_categories(\@parsed_cats);
    # the final goal is to avoid the use of hardcoded text_count

    # XAPIAN INDEXING, excluding specials
    if ($class eq 'text') {
        $self->xapian->index_text($title, $logger);
        # and update the text structure
        $title->text_html_structure(1);
        # and add or remove from the archives
        my $pubdate = $title->pubdate;
        my @months;
        # populate
        if ($title->is_published) {
            if (my $pubdate = $title->pubdate) {
                push @months, {
                               site_id => $self->id,
                               month => $pubdate->month,
                               year => $pubdate->year,
                              };
            }
        }
        $title->set_monthly_archives(\@months);
    }
    $title->muse_headers->delete;
    if (my $header_obj = AmuseWikiFarm::Utils::Amuse::muse_header_object($title->f_full_path_name)) {
        my %header = %{$header_obj->header};
        foreach my $k (keys %header) {
            # prevent a mess
            if (length($k) < 255) {
                $title->muse_headers->create({
                                              muse_header => $k,
                                              muse_value => $header{$k},
                                             });
            }
        }
    }
    $title->scan_and_store_links($logger) if $self->enable_backlinks;
    if (my $teaser_length = $self->automatic_teaser) {
        $title->autogenerate_teaser($teaser_length, $logger);
    }
    $guard->commit;
    return $title;
}

=head2 title_fields

Return an hashref with the keys set to each column of the Title row.

=head2 list_fixed_categories

Return an arrayref with the list of the fixed category, if they exist,
or nothing.

=cut

sub title_fields {
    my $self = shift;
    my %fields = map { $_ => 1 } $self->titles->result_source->columns;
    return \%fields;

}

sub list_fixed_categories {
    my $self = shift;
    if (my $list = $self->fixed_category_list) {
        return [ split(/\s+/, $list) ];
    }
    else {
        return;
    }
}

sub locales_dir {
    my $self = shift;
    return File::Spec->catdir($self->path_for_site_files, 'locales');
}

sub lexicon_file {
    my $self = shift;
    return File::Spec->catfile($self->path_for_site_files, "lexicon.json");
}

has lexicon => (is => 'ro',
                isa => 'Maybe[HashRef]',
                lazy => 1,
                builder => '_build_lexicon');

sub _build_lexicon {
    my $self = shift;
    my $file = $self->lexicon_file;
    if (-f $file) {
        my $json = Text::Amuse::Compile::Utils::read_file($file);
        my $hashref = AmuseWikiFarm::Utils::Amuse::from_json($json);
        if ($hashref and ref($hashref) eq 'HASH') {
            return $hashref;
        }
        elsif ($@) {
            log_fatal { $@ };
        }
    }
    return undef;
}

sub multilanguage_list {
    my ($self) = @_;
    my $list = $self->multilanguage;
    if ($list) {
        my @langs =  grep { /\w/  } split(/\s+/, $list);
        my @out;
        my $check = $self->known_langs;
        foreach my $i (@langs) {
            if (my $label = $check->{$i}) {
                push @out, {
                            code => $i,
                            label => $label,
                           },
            }
        }
        return \@out;
    }
    else {
        return;
    }
}

sub supported_locales {
    my ($self) = @_;
    my $check = $self->known_langs;
    my @all = map { $_->{code} } @{ $self->multilanguage_list || [] };
    push @all, $self->locale;
    my %out;
    foreach my $lang (@all) {
        if ($check->{$lang}) {
            $out{$lang}++;
        }
    }
    return sort keys %out;
}

sub is_without_authors {
    my ($self, $logged_in) = @_;
    return !$self->categories->by_type('author')
      ->with_texts(deferred => $logged_in || $self->show_preview_when_deferred)
      ->first;
}

sub is_without_topics {
    my ($self, $logged_in) = @_;
    return !$self->categories->by_type('topic')
      ->with_texts(deferred => $logged_in || $self->show_preview_when_deferred)
      ->first;
}

has options_hr => (
                   is => 'ro',
                   isa => 'HashRef[Str]',
                   lazy => 1,
                   builder => '_build_options_hr',
                  );

sub _build_options_hr {
    my $self = shift;
    my $options = $self->site_options;
    my %opts;
    while (my $option = $options->next) {
        $opts{$option->option_name} = $option->option_value;
    }
    return \%opts;
}


=head1 SCANNING

=head2 repo_find_files

Return an hashrefs, where each key is the relative path to the file,
and the value is the epoch timestamp in seconds.

=cut

sub repo_find_files {
    my $self = shift;
    my %files;
    my $root = $self->repo_root;
    find (sub {
              my $file = $_;
              return unless -f $file;
              my $relpath = File::Spec->abs2rel($File::Find::name, $root);
              if (muse_filepath_is_valid($relpath)) {
                  die "Something is wrong here" if exists $files{$relpath};
                  $files{$relpath} = (stat($file))[9];
              }
              else {
                  warn "Discarding $relpath\n" if $relpath =~ m/\.muse$/;
              }
          }, $root);
    return \%files;
}

=head2 repo_find_tracked_files

Return an hashrefs, where each key is the relative path to the file,
and the value is the epoch timestamp in seconds.

=cut

sub repo_find_tracked_files {
    my $self = shift;
    my %files;
    my $root = $self->repo_root;

    foreach my $f ($self->titles, $self->attachments) {

        # ignore bogus entries without a timestamp (placeholders for revisions)
        my $abspath = $f->f_full_path_name;
        next unless $abspath;

        # ignore files in the staging area
        next unless $f->f_archive_rel_path;

        my $relpath = File::Spec->abs2rel($f->f_full_path_name, $root);

        if (muse_filepath_is_valid($relpath)) {
            die "Something is wrong here" if exists $files{$relpath};
            $files{$relpath} = $f->f_timestamp_epoch;
        }
        else {
            warn "Discarding $relpath, not in the right directory\n";
        }
    }
    return \%files;
}

=head2 repo_find_changed_files

Compare the timestamp found in the tree with the ones stored in the
db, and run a check. It return an hashref with three keys, C<changed>,
C<new>, C<removed>. Each of them points to an arrayref with the list
of relative paths.

=cut

sub repo_find_changed_files {
    my $self = shift;
    my $report = {
                  new => [],
                  changed => [],
                  removed => [],
                 };
    my $in_tree = $self->repo_find_files;
    Dlog_debug { "Files are $_" } $in_tree;
    my $in_db = $self->repo_find_tracked_files;
    foreach my $file (keys %$in_db) {
        if (exists $in_tree->{$file}) {
            if ($in_tree->{$file} != $in_db->{$file}) {
                push @{$report->{changed}}, $file;
            }
        }
        else {
            push @{$report->{removed}}, $file;
        }
    }
    # and the other way around
    foreach my $file (keys %$in_tree) {
        unless (exists $in_db->{$file}) {
            push @{$report->{new}}, $file;
        }
    }
    return $report;
}

=head3 repo_git_pull($remote_name)

Try to pull the remote git into the master branch (fast-forward only).

You want to call C<update_db_from_tree> afterward.

=head3 repo_git_push($remote_name)

Try to push master into the remote git.

=cut

sub repo_git_pull {
    shift->_repo_git_action(pull => @_);
}

sub repo_git_push {
    shift->_repo_git_action(push => @_);
}

sub _repo_git_action {
    my ($self, $action, $remote, $logger) = @_;
    die "Wrong usage" unless $action;
    my @out;
    if (my $git = $self->git) {
        $remote ||= 'origin';
        my $fatal;
        if ($action eq 'push') {
            eval {
                @out = $git->push($remote, 'master');
            };
            $fatal = $@;
        }
        elsif ($action eq 'pull') {
            eval {
                @out = $git->pull({ ff_only => 1 }, $remote, 'master');
            };
            $fatal = $@;
        }
        else {
            die "Bad usage $action";
        }
        if ($fatal) {
            push @out, $fatal->error;
        }
        if (my $err = $git->ERR) {
            push @out, @$err;
        }
    }
    else {
        push @out, "Not under git!";
    }
    if (@out) {
        @out = map { $_ . "\n" } @out;
        if ($logger) {
            $logger->(@out);
        }
        else {
            print @out;
        }
    }
    return;
}

=head3 update_db_from_tree($logger)

Check the consistency of the repo and the db. Index and compile
new/changed files and purge the removed ones.

Pass the first argument (a sub ref) as logger to
L<Text::Amuse::Compile> if present.

=cut

sub update_db_from_tree {
    my ($self, $logger) = @_;
    $logger ||= sub { print @_ };
    my @files = $self->_pre_update_db_from_tree($logger);
    $self->compile_and_index_files(\@files, $logger);
}

sub _pre_update_db_from_tree {
    my ($self, $logger) = @_;
    $logger ||= sub { print @_ };
    my $todo = $self->repo_find_changed_files;
    # first delete
    foreach my $purge (@{ $todo->{removed} }) {
        if (my $found = $self->find_file_by_path($purge)) {
            $logger->("Removing $purge from database\n");
            $found->delete;
        }
        else {
            log_warn { "$purge was not present in the db!" };
        }
    }
    eval {
        if (my @generated =
            AmuseWikiFarm::Utils::LexiconMigration::convert($self->lexicon,
                                                            $self->locales_dir)) {
            $logger->("Updated the following file from lexicon file:\n"
                      . join("\n", @generated) . "\n");
        }
    };
    if ($@) {
        $logger->("Exception migrating lexicon to PO: $@");
    }
    my @files = (sort @{ $todo->{new} }, @{ $todo->{changed} });
    return @files;
}


=head2 find_file_by_path($path)

Return a title or attachment depending on the path provided (or
nothing if not found).

=cut

sub find_file_by_path {
    my ($self, $path) = @_;
    return unless $path;
    my $fullpath = File::Spec->rel2abs($path, $self->repo_root);
    if ($fullpath =~ m/\.muse$/) {
        my $title = $self->titles->find_file($fullpath);
        return $title;
    }
    else {
        my $file = $self->attachments->find_file($fullpath);
        return $file;
    }
}

=head2 git

Return the Git::Wrapper object bound to the repo (or undef if it's not under git).

=cut

sub git {
    my $self = shift;
    return unless $self->repo_is_under_git;
    my $root = $self->repo_root;
    require Git::Wrapper;
    my $git = Git::Wrapper->new($root);
    return $git;
}



=head2 remote_gits

Return a list of remote gits found in the repo. Each element is an
hashref with the following keys: C<name>, C<url>, C<action>.

=cut

sub remote_gits {
    my $self = shift;
    my $git = $self->git;
    return unless $git;
    my @remotes = $git->remote('-v');
    my @out;
    foreach my $remote (@remotes) {
        my ($name, $url, $action) = split(/\s+/, $remote, 3);
        if ($action =~ m/\s*\((.+)\)\s*/) {
            push @out, { name => $name,
                         url => $url,
                         action => $1 };
        }
    }
    return @out;
}

=head2 remote_gits_hashref

Return an hashref (empty hashref is no git or no remotes) with this structure:

 {
  origin => {
             fetch => $remotedir,
             push  => $remotedir,
            },
  other => {
            fetch => $repo,
           },
  # ....
 }

This is used for validation of actions.

=cut

sub remote_gits_hashref {
    my $self = shift;
    my @remotes = $self->remote_gits;
    my $out = {};
    foreach my $remote (@remotes) {
        $out->{$remote->{name}}->{$remote->{action}} = $remote->{url};
    }
    return $out;
}

sub add_git_remote {
    my ($self, $name, $url) = @_;
    my $git = $self->git;
    return unless $git;
    log_debug { "Trying to add $name and $url" };
    my ($valid_name, $valid_url);
    if ($name =~ m/\A\s*([0-9a-zA-Z]+)\s*\z/) {
        $valid_name = lc($1);
    }
    my $pathre = qr{(/[0-9a-zA-Z\._-]+)+/?};
    if ($url =~ m{\A\s*(((git|https?):/)?$pathre)\s*\z}) {
        $valid_url = $1;
    }
    if ($valid_url && $valid_name && !$self->remote_gits_hashref->{$valid_name}) {
        log_info { "Adding $valid_name $valid_url" };
        $git->remote(add => $valid_name => $valid_url);
        return $valid_name;
    }
    else {
        log_error { "$name and/or $url are invalid" };
        return;
    }
}

sub remove_git_remote {
    my ($self, $name) = @_;
    my $git = $self->git;
    if ($self->remote_gits_hashref->{$name}) {
        $git->remote(rm => $name);
        return 1;
    }
    else {
        return;
    }
}


=head2 special_list

Return a list where each element is an hashref describing the special
pages we have and has the following keys: C<uri>, C<name>.

The index pages are excluded.

=cut

sub special_list {
    my $self = shift;
    my @list = $self->titles->published_specials
      ->search({
                uri => { -not_like => 'index%' },
               },
               { columns => [qw/title uri/] });
    my @out;
    foreach my $l (@list) {
        push @out, {
                    uri => $l->uri,
                    name => $l->title || $l->uri
                   };
    }
    my @links = $self->site_links->search(undef,
                                          { order_by => [qw/sorting_pos label/] });
    foreach my $l (@links) {
        push @out, {
                    full_url => $l->url,
                    name => $l->label,
                   };
    }
    return @out;
}

=head2 update_or_create_user(\%attrs, $role)
       update_or_create_user($username, $role)

Create or update a user and add it to our user unless already present.
If an hashref is passed, it must contain the username key with some
value. Also, the sanity of the username is checked.

Returns the User object.

If the optional $role is passed, the role will be assigned, defaulting
to librarian if not passed.

=cut

sub update_or_create_user {
    my ($self, $details, $role) = @_;
    $role ||= 'librarian';
    # first, search our users

    my $username;

    if (ref($details)) {
        $username = $details->{username};
    }
    else {
        $username = $details;
        $details = { username => $username };
    }

    die "Missing username" unless $username;
    my $cleaned = muse_naming_algo($username);
    die "$username doesn't match $cleaned" unless $username eq $cleaned;

    # search the site
    my $user = $self->users->find({ username => $username });
    if ($user) {
        my %query = %$details;
        delete $query{username};
        if (%query) {
            $user->update(\%query)->discard_changes;
        }
    }
    else {
        # still here? check the existing userbase
        $user = $self->result_source->schema->resultset('User')
          ->update_or_create({ %$details })->discard_changes;
        $self->add_to_users($user);
    }
    # check the roles
    unless ($user->roles->find({ role => $role })) {
        $user->add_to_roles({ role => $role });
    }
    return $user;
}

sub my_topics {
    my $self = shift;
    return $self->categories->by_type('topic');
}

sub my_authors {
    my $self = shift;
    return $self->categories->by_type('author');
}

=head2 update_from_params(\%params)

If the params is valid, perform an update, otherwise return the error.

=cut

sub update_from_params_restricted {
    my ($self, $params) = @_;
    return unless $params;
    my %fixed_values = (
                        active            => 'value',

                        logo              => 'value_or_empty',
                        logo_with_sitename => 'value',

                        canonical         => 'value',
                        sitegroup         => 'value',

                        ttdir             => 'value',

                        use_luatex               => 'option',

                        vhosts            => 'delete',

                        secure_site       => 'value',
                        secure_site_only  => 'value',
                        acme_certificate  => 'value',
                        ssl_key           => 'value_or_empty',
                        ssl_chained_cert  => 'value_or_empty',
                        ssl_cert          => 'value_or_empty',
                        ssl_ca_cert       => 'value_or_empty',

                       );
    my $abort;
    foreach my $value (keys %fixed_values) {
        if (exists $params->{$value}) {
            log_error { "Restricted update passed a fixed value, $value, aborting" };
            $abort++;
        }
        my $type = $fixed_values{$value};
        if ($type eq 'value') {
            $params->{$value} = $self->$value;
        }
        elsif ($type eq 'value_or_empty') {
            $params->{$value} = $self->$value || '';
        }
        elsif ($type eq 'option') {
            $params->{$value} = $self->get_option($value);
        }
        elsif ($type eq 'delete') {
            delete $params->{$value};
        }
        else {
            die "$type is wrong";
        }
    }
    if ($abort) {
        return;
    }
    else {
        return $self->update_from_params($params);
    }
}


sub update_from_params {
    my ($self, $params) = @_;
    Dlog_debug { "options are $_" } ($params);
    my @errors;
    # allwoing to set bare_html, we get the chance to the sloppy admin
    # to break the app, but hey...

    # first round: booleans. Here there is not much to do. If it's set, 1,
    # otherwise 0
    my @booleans = (qw/    pdf a4_pdf lt_pdf
                       sl_pdf
                       logo_with_sitename
                       cgit_integration
                       secure_site
                       active
                       blog_style
                       acme_certificate
                       secure_site_only
                       twoside nocoverpage/);
    foreach my $boolean (@booleans) {
        if (delete $params->{$boolean}) {
            $self->$boolean(1);
        }
        else {
            $self->$boolean(0);
        }
    }

    # strings: same here, nothing which should go too wrong, save for
    # the the length.
    my @strings = (qw/magic_answer magic_question fixed_category_list
                      multilanguage
                      theme
                      ssl_key
                      ssl_cert
                      ssl_ca_cert
                      ssl_chained_cert
                      sitename siteslogan logo mail_notify mail_from
                      sitegroup ttdir/);
    foreach my $string (@strings) {
        my $param = delete $params->{$string};
        if (defined $param) {
            $param =~ s/\s+/ /gs;
            $param =~ s/^\s+//;
            $param =~ s/\s+$//;
            if (length($param) < 256) {
                $self->$string($param);
            }
            else {
                push @errors, "$string $param exceeds 255 chars";
            }
        }
        else {
            push @errors, "$string is not defined!";
        }
    }

    if ($params->{canonical} and
        $params->{canonical} =~ m/\A$RE{net}{domain}{-nospace}{-rfc1101}\z/) {
        my $canonical = delete $params->{canonical};
        $self->canonical($canonical);
    }
    else {
        log_error { ($params->{canonical} || '') . "doesn't match"
                      . $RE{net}{domain}{-nospace}{-rfc1101} };
        push @errors, "Canonical is mandatory";
    }


    # ranges
    my %ranges = (
                  division => [9, 15],
                  fontsize => [10, 12],
                  bb_page_limit => [10, 2000], # 2000 pages should be enough...
                 );

    foreach my $integer (keys %ranges) {
        my $int = delete $params->{$integer};
        unless (defined $int and $int =~ m/^[1-9][0-9]*$/) {
            push @errors, "$integer $int doesn't look like an integer";
            next;
        }
        my $range = $ranges{$integer};
        if ($int < $range->[0] and $int > $range->[1]) {
            push @errors, "$integer $int is out of range";
        }
        else {
            $self->$integer($int);
        }
    }

    # most critical: strings which need to have exactly defined values
    #      'mode' => 'modwiki',
    #      'papersize' => 'a4',
    #      'mainfont' => 'Charis SIL',
    #      'locale' => 'hr',
    #      'bcor' => '0mm'

    # these are select options, so just ignore wrong values
    my $mode = delete $params->{mode};
    if ($mode && $self->available_modes->{$mode}) {
        $self->mode($mode);
    }
    else {
        push @errors, "Wrong mode!";
    }

    my $locale = delete $params->{locale};
    if ($locale && $self->known_langs->{$locale}) {
        $self->locale($locale);
    }
    else {
        push @errors, "Wrong locale!";
    }


    # for papersize and fonts, we ask the bookbuilder
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $self) ;

    my $ppsize = delete $params->{papersize};
    if ($ppsize && $bb->papersize_values_as_hashref->{$ppsize}) {
        $self->papersize($ppsize);
    }
    else {
        push @errors, "Wrong papersize!";
    }

    foreach my $fontfamily (qw/mainfont sansfont monofont/) {
        my $font = delete $params->{$fontfamily};
        Dlog_debug { "Available fonts $_" }  $bb->available_fonts;
        if ($font && $bb->available_fonts->{$font}) {
            $self->$fontfamily($font);
        }
        else {
            $font ||= "NONE";
            push @errors, "Wrong $fontfamily $font!";
        }
    }
    if (my $beamertheme = delete $params->{beamertheme} || '') {
        my %avail = map { $_ => 1 } @{ $bb->beamer_themes_values };
        Dlog_debug { "available beamer theme $_ and $beamertheme" } \%avail;
        if ($avail{$beamertheme}) {
            $self->beamertheme($beamertheme);
        }
        else {
            push @errors, "Wrong Beamer theme: $beamertheme";
        }
    }
    if (my $beamercolortheme = delete $params->{beamercolortheme} || '') {
        my %avail = map { $_ => 1 } @{ $bb->beamer_color_themes_values };
        Dlog_debug { "available beamer color theme $_ and $beamercolortheme" }
          \%avail;
        if ($avail{$beamercolortheme}) {
            $self->beamercolortheme($beamercolortheme);
        }
        else {
            push @errors, "Wrong Beamer Color theme: $beamercolortheme";
        }
    }


    my $bcor = delete $params->{bcor};
    if ($bcor && $bcor =~ m/^([0-9]+mm)$/) {
        $self->bcor($1);
    }
    else {
        push @errors, "Invalid binding correction\n";
    }

    my $opening = delete $params->{opening};
    if ($opening) {
        my %avail_openings = map { $_ => 1 } @{ $bb->opening_values };
        if ($avail_openings{$opening}) {
            $self->opening($opening);
        }
        else {
            push @errors, "Invalid opening!";
        }
    }
    else {
        push @errors, "Invalid opening!";
    }
    # unclear if it's enough to prevent a memory cycle. Probably it
    # is, as $bb goes away, which references $self.
    undef $bb;

    my @vhosts;
    # ignore missing vhosts
    if (my $vhosts = delete $params->{vhosts}) {
        @vhosts = grep { m/\w/ } split(/\s+/, $vhosts);
        if (@vhosts) {
            my @existing = $self->result_source->schema->resultset('Vhost')
              ->search( {
                         name => [ @vhosts ],
                         site_id => { '!=' => $self->id }
                        } );
            foreach my $ex (@existing) {
                push @errors, "Found existing vhost: " . $ex->name;
            }
        }
    }

    my @options;
    # these are numerics
    foreach my $option (qw/latest_entries_for_rss
                           paginate_archive_after
                           pagination_size
                           pagination_size_search
                           pagination_size_monthly
                           pagination_size_latest
                           pagination_size_category
                           automatic_teaser
                          /) {
        my $value = 0;
        if (my $set_to = delete $params->{$option}) {
            if ($set_to =~ m/([1-9][0-9]*)/) {
                $value = $1;
            }
            else {
                push @errors, "$option should be numeric";
            }
        }
        push @options, {
                        option_name => $option,
                        option_value => $value,
                       };
    }

    # this is totally arbitrary
    foreach my $option (qw/html_special_page_bottom use_luatex
                           left_layout_html
                           right_layout_html
                           top_layout_html
                           bottom_layout_html
                           do_not_enforce_commit_message
                           text_infobox_at_the_bottom
                           freenode_irc_channel
                           turn_links_to_images_into_images
                           enable_video_widgets
                           show_preview_when_deferred
                           titles_category_default_sorting
                           enable_order_by_sku
                           enable_backlinks
                           use_js_highlight
                           edit_option_page_left_bs_columns
                           edit_option_show_cheatsheet
                           edit_option_show_filters
                           edit_option_preview_box_height
                           show_type_and_number_of_pages
                          /) {
        my $value = delete $params->{$option} || '';
        # clean it up from leading and trailing spaces
        $value =~ s/\A\s*//s;
        $value =~ s/\s*\z//s;
        push @options, {
                        option_name => $option,
                        option_value => $value,
                       };
    }

    my @site_links = $self->deserialize_links(delete $params->{site_links});

    if (%$params) {
        push @errors, "Unprocessed parameters found: "
          . join(", ", keys %$params);
    }


    # no error? update the db
    unless (@errors) {
        my $guard = $self->result_source->schema->txn_scope_guard;
        Dlog_info { "Updating site settings $_ " } +{ $self->get_dirty_columns };
        $self->update;
        if (@vhosts) {
            Dlog_info { "Updating vhosts to $_" }
              +{
                to => \@vhosts,
                from => [ map { $_->name } $self->vhosts ],
               };
            # delete and reinsert, even if it doesn't feel too right
            $self->vhosts->delete;
            foreach my $vhost (@vhosts) {
                $self->vhosts->create({ name => $vhost });
            }
        }
        $self->site_links->delete;
        Dlog_info { "Updating links to $_" }
          +{
            from => [ map { +{ url => $_->url,
                               label => $_->label,
                               sorting_pos => $_->sorting_pos
                             } } $self->site_links ],
            to => \@site_links,
           };
        foreach my $link (@site_links) {
            $self->site_links->create($link);
        }
        Dlog_info { "Updating options to $_" }
          +{
            from => [ map { +{
                              option_name => $_->option_name,
                              option_value => $_->option_value
                             } } $self->site_options ],
            to => \@options,
           };
        foreach my $opt (@options) {
            $self->site_options->update_or_create($opt);
        }
        $guard->commit;
        $self->configure_cgit;
        $self->check_and_update_custom_formats;
    }
    # in any case discard the changes
    $self->discard_changes;
    @errors ? return join("\n", @errors) : return;
}

sub configure_cgit {
    my $self = shift;
    my $schema = $self->result_source->schema;
    my $cgit = AmuseWikiFarm::Utils::CgitSetup->new(schema => $schema);
    $cgit->configure;
}

sub deserialize_links {
    my ($self, $string) = @_;
    my @links;
    return @links unless $string;
    my @lines = grep { $_ } split(/\r?\n/, $string);
    return @links unless @lines;
    my $order = 0;
    foreach my $line (@lines) {
        if ($line =~ m{^\s*(https?://\S+)\s+(.*?)\s*$}) {
            push @links, {
                          url => $1,
                          label => $2,
                          sorting_pos => $order++,
                         };
        }
    }
    return @links;
}

sub serialize_links {
    my $self = shift;
    my $links = $self->site_links->search(undef, { order_by => [qw/sorting_pos label/] });
    my @lines;
    while (my $link = $links->next) {
        push @lines, $link->url . ' ' . $link->label;
    }
    if (@lines) {
        return join("\n", @lines);
    }
    else {
        return '';
    }
}

sub translations_list {
    my $self = shift;
    # get all the texts
    my $rs = $self->titles->search({ f_class => 'text' },
                                   {
                                    columns => [qw/uid title uri f_class/],
                                    order_by => [qw/list_title/],
                                   });
    my %all;
    while (my $text = $rs->next) {
        my $uid = $text->uid || 0; # consider '', null and 0 all the same
        $all{$uid} ||= [];
        push @{$all{$uid}}, {
                             full_uri => $text->full_uri,
                             title => $text->uri,
                             full_edit_uri => $text->full_edit_uri,
                            };
    }
    my @out;
    my @list = sort keys %all;
    foreach my $k (@list) {
        push @out, { uid => $k,
                     texts => delete($all{$k}) };
    }
    return \@out;
}


=head2 initialize_git

If there is no repo, initialize a git one.

=cut

sub initialize_git {
    my $self = shift;
    my $root = $self->repo_root;
    if (-d $root) {
        warn "$root already exist, skipping the git initialization";
        return;
    }
    mkdir $self->repo_root
      or die "Couldn't create " . $self->repo_root . " " . $!;
    require Git::Wrapper;
    my $git = Git::Wrapper->new($self->repo_root);
    $git->init;
    $self->_create_repo_stub;
    $git->add('.');
    $git->commit({ message => 'Initial AMuseWiki setup' });
    $self->configure_cgit;
    return 1;
}

sub _create_repo_stub {
    my $self = shift;
    my $root = $self->repo_root;
    my $gitignore =<<'GITIGNORE';
?/??/*.pdf
?/??/*.a4.pdf
?/??/*.lt.pdf
?/??/*.epub
?/??/*.html
?/??/*.tex
?/??/*.log
?/??/*.tuc
?/??/*.aux
?/??/*.toc
?/??/*.ok
?/??/*.zip
?/??/*.status
specials/*.pdf
specials/*.a4.pdf
specials/*.lt.pdf
specials/*.epub
specials/*.html
specials/*.tex
specials/*.log
specials/*.tuc
specials/*.aux
specials/*.toc
specials/*.ok
specials/*.zip
specials/*.status
*~
GITIGNORE
    my $stub = "/* Empty by default, for local changes */\n";
    my $gitignore_path = File::Spec->catfile($root, '.gitignore');
    my $local_js_path = File::Spec->catfile($self->path_for_site_files, 'local.js');
    my $local_css_path = File::Spec->catfile($self->path_for_site_files, 'local.css');
    # create stub dirs
    foreach my $dir (qw/site_files specials uploads/) {
        my $target = File::Spec->catdir($root, $dir);
        mkdir $target or die "Couldn't create $target: $!";
    }
    my %stubs = (
                 $gitignore_path => $gitignore,
                 $local_js_path => $stub,
                 $local_css_path => $stub,
                );
    foreach my $file (keys %stubs) {
        open (my $fh, '>:encoding(UTF-8)', $file) or die "Couldn't open $file $!";
        print $fh $stubs{$file};
        close $fh or die $!;
    }
}

sub static_indexes_generator {
    my $self = shift;
    require AmuseWikiFarm::Archive::StaticIndexes;
    # pass a copy, so we avoid potential circular references
    return AmuseWikiFarm::Archive::StaticIndexes->new(site => $self->get_from_storage);
}

sub canonical_url {
    return shift->canonical_url_secure;
}

sub https_available {
    my $self = shift;
    return $self->secure_site || $self->secure_site_only;
}

sub canonical_url_secure {
    my $self = shift;
    if ($self->https_available) {
        return 'https://' . $self->canonical;
    }
    else {
        return 'http://' . $self->canonical;
    }
}


sub all_site_hostnames {
    my $self = shift;
    my @hostnames = ($self->canonical);
    push @hostnames, $self->alternate_hostnames;
    return @hostnames;
}

sub alternate_hostnames {
    my $self = shift;
    return sort map { $_->name } $self->vhosts;
}

sub full_name {
    my $self = shift;
    return $self->sitename || $self->canonical;
}

sub latest_entries_for_rss_rs {
    my $self = shift;
    return $self->titles->latest($self->latest_entries_for_rss);
}

sub latest_entries_for_rss {
    return shift->get_option('latest_entries_for_rss') || 25;
}

sub paginate_archive_after {
    return shift->get_option('paginate_archive_after') || 25;
}

sub freenode_irc_channel {
    return shift->get_option('freenode_irc_channel') || '#amusewiki';
}

sub turn_links_to_images_into_images {
    return shift->get_option('turn_links_to_images_into_images') || '';
}

sub enable_video_widgets {
    return shift->get_option('enable_video_widgets') || '';
}

sub pagination_needed {
    my ($self, $count) = @_;
    return 0 unless $count;
    my $min = $self->paginate_archive_after;
    $count > $min ? return 1 : return 0;
}


sub get_option {
    my ($self, $lookup) = @_;
    if ($lookup) {
        return $self->options_hr->{$lookup};
    }
    else {
        return undef;
    }
}

sub html_special_page_bottom {
    return shift->get_option('html_special_page_bottom') || '';
}

sub left_layout_html {
    return shift->get_option('left_layout_html') || '';
}

sub right_layout_html {
    return shift->get_option('right_layout_html') || '';
}

sub top_layout_html {
    return shift->get_option('top_layout_html') || '';
}

sub bottom_layout_html {
    return shift->get_option('bottom_layout_html') || '';
}


sub titles_available_sortings {
    my $self = shift;
    return $self->titles->available_sortings(sku => $self->enable_order_by_sku);
}

sub validate_text_category_sorting {
    my ($self, $option) = @_;
    my @available = $self->titles_available_sortings;
    if ($option) {
        if (grep { $_->{name} eq $option } @available) {
            return $option;
        }
    }
    if ($self->blog_style) {
        return 'pubdate_desc';
    }
    else {
        return $available[0]{name};
    }
}

sub titles_category_default_sorting {
    my $self = shift;
    my $option = $self->get_option('titles_category_default_sorting') || '';
    return $self->validate_text_category_sorting($option);
}

sub enable_order_by_sku {
    return shift->get_option('enable_order_by_sku') || '';
}

sub enable_backlinks {
    return shift->get_option('enable_backlinks') || '';
}

sub pagination_size {
    return shift->get_option('pagination_size') || 10;
}

sub pagination_size_latest {
    my $self = shift;
    return $self->get_option('pagination_size_latest') || $self->pagination_size;
}

sub pagination_size_category {
    my $self = shift;
    return $self->get_option('pagination_size_category') || $self->pagination_size;
}

sub pagination_size_search {
    my $self = shift;
    return $self->get_option('pagination_size_search') || $self->pagination_size;
}

sub pagination_size_monthly {
    my $self = shift;
    return $self->get_option('pagination_size_monthly') || $self->pagination_size;
}

sub automatic_teaser {
    my $self = shift;
    if (my $value = $self->get_option('automatic_teaser')) {
        if ($value =~ m/\A([1-9][0-9]*)\z/) {
            return $1;
        }
    }
    return 0;
}

sub show_type_and_number_of_pages {
    my $self = shift;
    return $self->get_option('show_type_and_number_of_pages') || '';
}


sub text_infobox_at_the_bottom {
    return shift->get_option('text_infobox_at_the_bottom') || '';
}

sub show_preview_when_deferred {
    my $self = shift;
    if ($self->get_option('show_preview_when_deferred')) {
        return 1;
    }
    else {
        return '';
    }
}

sub use_luatex {
    my ($self) = @_;
    $self->get_option('use_luatex') ? 1 : 0;
}

sub do_not_enforce_commit_message {
    my ($self) = @_;
    $self->get_option('do_not_enforce_commit_message') ? 1 : 0;
}

sub use_js_highlight {
    my ($self, $force) = @_;
    if (my $langs = $self->use_js_highlight_value || $force ) {
        my @true_langs = grep { /\A[a-z]+\z/ } split(/\s+/, $langs);
        return AmuseWikiFarm::Utils::Amuse::to_json({ languages => \@true_langs });
    }
    return '';
}

sub use_js_highlight_value {
    my $self = shift;
    return $self->get_option('use_js_highlight');
}

sub sl_tex {
    return shift->sl_pdf;
}

sub mail_from_default {
    my $self = shift;
    if (my $mail = $self->mail_from) {
        return $mail;
    }
    else {
        return 'noreply@' . $self->canonical;
    }
}

sub popular_titles {
    my ($self, $page) = @_;
    return $self->title_stats->popular_texts($page, $self->pagination_size);
}

=head2 serialize_site

Return an hashref with the serialized site, with options, virtual
host, etc. so you can call the resultset
L<AmuseWikiFarm::Schema::ResultSet::Site> C<deserialize_site> call on
this to clone a site.

=cut

sub _columns_with_no_embedded_id {
    my $row = shift;
    my $source = $row->result_source;
    my %cols = $row->get_columns;

    foreach my $col ($row->columns) {
        my %info = %{ $source->column_info($col) };
        if ($info{is_auto_increment} or
            $info{is_foreign_key}) {
            log_debug { "Deleting $col $cols{$col} from $row" };
            delete $cols{$col};
        }
    }
    return %cols;
}

sub serialize_site {
    my ($self) = @_;
    my %data =  $self->get_columns;

    foreach my $method ($self->result_source->resultset->site_serialize_related_rels) {
        my @records;
      ROW:
        foreach my $row ($self->$method->all) {
            # we store the categories only if we have descriptions attached
            my %row_data = _columns_with_no_embedded_id($row);
            if ($method eq 'categories') {
                my @descriptions;
                foreach my $desc ($row->category_descriptions) {
                    my %hashref = _columns_with_no_embedded_id($desc);
                    push @descriptions, \%hashref;
                }
                if (@descriptions) {
                    $row_data{category_descriptions} = \@descriptions;
                }
                else {
                    # skip the categories without descriptions
                    next ROW;
                }
            }
            push @records, \%row_data;
        }
        $data{$method} = \@records;
    }
    # then the users
    my @users;
    foreach my $user ($self->users) {
        my %user_data = _columns_with_no_embedded_id($user);
        foreach my $method (qw/roles
                               bookbuilder_profiles/) {
            $user_data{$method} = [ map { +{ _columns_with_no_embedded_id($_) } } $user->$method->all ];
        }
        push @users, \%user_data;
    }
    $data{users} = \@users;
    return \%data;
}

sub populate_monthly_archives {
    my $self = shift;
    my $guard = $self->result_source->schema->txn_scope_guard;
    # clear all
    $self->monthly_archives->delete;
    my $texts = $self->titles->published_texts->search({}, { columns => [qw/id pubdate/] });
    while (my $text = $texts->next) {
        if (my $pubdate = $text->pubdate) {
            my $month = $self->monthly_archives->find_or_create({
                                                                 month => $pubdate->month,
                                                                 year => $pubdate->year,
                                                                });
            $month->add_to_titles($text);
        }
    }
    $guard->commit;
}

sub bootstrap_themes {
    my $self = shift;
    my @themes = (qw/amusewiki
                     amusecosmo
                     amusejournal

                     cerulean
                     cosmo
                     cyborg
                     darkly
                     flatly
                     journal
                     lumen
                     readable
                     simplex
                     slate
                     spacelab
                     united
                    /);
    return @themes;
}

sub bootstrap_theme {
    my $self = shift;
    my $theme = $self->theme || 'amusewiki';
    my %avail = map { $_ => 1 } $self->bootstrap_themes;
    if ($avail{$theme}) {
        return $theme;
    }
    else {
        log_error { "Theme $theme not found! for site " . $self->canonical };
        return 'amusewiki';
    }
}

sub bootstrap_theme_list {
    my $self = shift;
    my @themes = map { +{ name => $_, label => ucfirst($_) } } $self->bootstrap_themes;
    Dlog_debug { "Themes are $_" } \@themes;
    return @themes;
}

sub xapian_reindex_all {
    my $self = shift;
    my $xapian = $self->xapian;
    my @titles = $self->titles->texts_only;
    my $logger = sub { print join(" ", @_) };
    foreach my $title (@titles) {
        $xapian->index_text($title, $logger);
    }
}

=head1 WEBSERVER options

These options only affect the webserver configuration, but we have to
store them here to fully automate that, without calling the script
with different options which are not going to cover any case.

They are stored in the C<site> table to enable a more straightforward
setting from the sql monitor. (Say you have a wildcard cert for all
the sites, you can just do a single update to set them).

Please note that ssl_cert and ssl_ca_cert are not used anywhere,
because we don't provide an apache config generator. But if there is
the need for this, we have already the fields ready.

=head2 ssl_key

Used by both Apache and nginx.

=head2 ssl_cert

Used by Apache.

=head2 ssl_ca_cert

Used by Apache

=head2 ssl_chained_cert

Used by nginx (concatenation of the certificate and the CA
certificate).

=head2 secure_site_only

This affects only the generation of the nginx conf

=head1 EDITING OPTIONS

Stored in the site_options table and wrapped here. Compare with User
class.

=over 4

=item edit_option_preview_box_height

=item edit_option_show_filters

=item edit_option_show_cheatsheet

=item edit_option_page_left_bs_columns

=back

=cut


sub edit_option_preview_box_height {
    my $self = shift;
    my $value = $self->get_option('edit_option_preview_box_height');
    if (defined $value and
        $value =~ m/\A[1-9][0-9]*\z/) {
        return $value;
    }
    return 500;
}

sub edit_option_show_filters {
    my $self = shift;
    my $value = $self->get_option('edit_option_show_filters');
    if (defined $value) {
        $value ? return 1 : return 0;
    }
    else {
        return 1;
    }
}
sub edit_option_show_cheatsheet {
    my $self = shift;
    my $value = $self->get_option('edit_option_show_cheatsheet');
    if (defined $value) {
        $value ? return 1 : return 0;
    }
    else {
        return 1;
    }
}

sub edit_option_page_left_bs_columns {
    my $self = shift;
    my $value = $self->get_option('edit_option_page_left_bs_columns');
    if (defined $value and $value =~ m/\A[1-9][0-9]*\z/) {
        return $value;
    }
    return 6;
}

sub update_db_from_tree_async {
    my ($self, $logger, $username) = @_;
    $logger ||= sub { print @_ };
    my @files = $self->_pre_update_db_from_tree($logger);
    my $now = DateTime->now;
    return $self->bulk_jobs->reindexes->create({
                                     created => $now,
                                     status => (scalar(@files) ? 'active' : 'completed'),
                                     completed => (scalar(@files) ? undef : $now),
                                     username => $username,
                                     jobs => [
                                              map {
                                                  +{
                                                    site_id => $self->id,
                                                    username => $username,
                                                    task => 'reindex',
                                                    status => 'pending',
                                                    created => $now,
                                                    priority => 19,
                                                    payload => AmuseWikiFarm::Utils::Amuse::to_json({ path => $_ }),
                                                  }
                                              } @files ]
                                    });
}

sub rebuild_formats {
    my ($self, $username) = @_;
    my @texts = $self->titles->published_or_deferred_all
      ->search(undef,
               {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                columns => [qw/id/],
               });
    Dlog_debug { "Texts are $_" } \@texts;
    my $site_id = $self->id;
    my $now = DateTime->now;
    if ($username) {
        $username =  AmuseWikiFarm::Utils::Amuse::clean_username($username);
    }
    # here we skip the rebuild_add method, because it would be a lot
    # slower to call $self->bulk_jobs->jobs->enqueue for each text.
    # They could be very well be thousands. Here, instead, the
    # creation is wrapped in a transaction and doesn't spawn objects
    # without reason.
    # loc('Rebuild')
    return $self->bulk_jobs->rebuilds->create({
                                     created => $now,
                                     username => $username,
                                     status => 'active',
                                     jobs => [ map {
                                         +{
                                           payload => AmuseWikiFarm::Utils::Amuse::to_json($_),
                                           site_id => $site_id,
                                           task => 'rebuild',
                                           status => 'pending',
                                           created => $now,
                                           priority => 20,
                                           username => $username,
                                          }
                                     } @texts ]
                                    });
}

sub active_custom_formats {
    my $self = shift;
    my @all = $self->custom_formats->active_only;
    return \@all;
}

sub root_install_directory {
    AmuseWikiFarm::Utils::Paths::root_install_directory();
}

sub mkits_location {
    AmuseWikiFarm::Utils::Paths::mkits_location();
}

sub templates_location {
    AmuseWikiFarm::Utils::Paths::templates_location();
}

sub localizer {
    my $self = shift;
    log_debug { "Loading localizer" };
    # there is no caching here. This should be called only outside the
    # web app if needed.
    require AmuseWikiFarm::Archive::Lexicon;
    return AmuseWikiFarm::Archive::Lexicon->new->localizer($self->locale,
                                                           $self->id);
}

sub mailer {
    my ($self, @args) = @_;
    require AmuseWikiFarm::Utils::Mailer;
    return AmuseWikiFarm::Utils::Mailer->new(mkit_location => $self->mkits_location->stringify, @args);
    # please note that the catalyst config could have injected args.
    # If we call this, those settings will be ignored, hence we permit
    # argument passing)
}

after insert => sub {
    my $self = shift;
    $self->discard_changes;
    $self->check_and_update_custom_formats;
};

__PACKAGE__->meta->make_immutable;

1;
