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

  data_type: 'text'
  is_nullable: 1

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

  data_type: 'text'
  is_nullable: 1

=head2 mail_from

  data_type: 'text'
  is_nullable: 1

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

=head2 binary_upload_max_size_in_mega

  data_type: 'integer'
  default_value: 8
  is_nullable: 0

=head2 git_token

  data_type: 'text'
  is_nullable: 1

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
  { data_type => "text", is_nullable => 1 },
  "sitename",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "siteslogan",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "theme",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "logo",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "mail_notify",
  { data_type => "text", is_nullable => 1 },
  "mail_from",
  { data_type => "text", is_nullable => 1 },
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
  "binary_upload_max_size_in_mega",
  { data_type => "integer", default_value => 8, is_nullable => 0 },
  "git_token",
  { data_type => "text", is_nullable => 1 },
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

=head2 amw_sessions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::AmwSession>

=cut

__PACKAGE__->has_many(
  "amw_sessions",
  "AmuseWikiFarm::Schema::Result::AmwSession",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 global_site_files

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::GlobalSiteFile>

=cut

__PACKAGE__->has_many(
  "global_site_files",
  "AmuseWikiFarm::Schema::Result::GlobalSiteFile",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 include_paths

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::IncludePath>

=cut

__PACKAGE__->has_many(
  "include_paths",
  "AmuseWikiFarm::Schema::Result::IncludePath",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 included_files

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::IncludedFile>

=cut

__PACKAGE__->has_many(
  "included_files",
  "AmuseWikiFarm::Schema::Result::IncludedFile",
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

=head2 nodes

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Node>

=cut

__PACKAGE__->has_many(
  "nodes",
  "AmuseWikiFarm::Schema::Result::Node",
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

=head2 site_category_types

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::SiteCategoryType>

=cut

__PACKAGE__->has_many(
  "site_category_types",
  "AmuseWikiFarm::Schema::Result::SiteCategoryType",
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

=head2 whitelist_ips

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::WhitelistIp>

=cut

__PACKAGE__->has_many(
  "whitelist_ips",
  "AmuseWikiFarm::Schema::Result::WhitelistIp",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 users

Type: many_to_many

Composing rels: L</user_sites> -> user

=cut

__PACKAGE__->many_to_many("users", "user_sites", "user");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-08-12 07:53:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ATTjOYTQyF1Mw++AIY4YoA

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
use constant ROOT => getcwd();
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
use JSON::MaybeXS ();
use AmuseWikiFarm::Utils::Paths ();
use Try::Tiny;
use Encode ();
use XML::FeedPP;
use Git::Wrapper;
use Bytes::Random::Secure;
use Email::Address;
use XML::OPDS;

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
    if (defined $base) {
        die "repo_root doesn't accept an argument";
    }
    return File::Spec->catdir(ROOT, $self->repo_root_rel);
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
                include_paths => $self->amuse_include_paths,
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
                icon => 'fa-file-epub',
                # loc('EPUB (for mobile devices)');
                desc => 'EPUB (for mobile devices)',
                oldid => "downloadepub",
               },
               {
                code => 'html',
                ext => '.html',
                icon => 'fa-print',
                # loc('Standalone HTML (printer-friendly)');
                desc => 'Standalone HTML (printer-friendly)',
                oldid => "downloadhtml",
               },
               {
                code => 'tex',
                ext => '.tex',
                icon => 'fa-file-code-o',
                # loc('XeLaTeX source');
                desc => 'XeLaTeX source',
                oldid => "downloadtex",
               },
               {
                code => 'muse',
                ext => '.muse',
                icon => 'fa-file-text-o',
                # loc('plain text source');
                desc => 'plain text source',
                oldid => "downloadsrc",
               },
               {
                code => 'zip',
                ext => '.zip',
                icon => 'fa-file-archive-o',
                # loc('Source files with attachments');
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
            $icon = 'fa-file-epub';
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

=head2 check_and_update_custom_formats

Method to spawn the standard CF, bound to the site flags
pdf/sl_pdf/a4_pdf/lt_pdf. Such flags are now informative only and are
toggled on /settings/formats. This method is called after the
insertion in the DB of a new site, at jobber startup and when visiting
/settings/formats.

Assert that all the formats are active, either by site flag or by
format active, and never deactivate anything.

Also assert that the custom formats are what they say they are.

=cut

sub fixed_formats_definitions {
    my %formats = (
                   pdf => {
                           initial => {
                                       format_alias => 'pdf',
                                       # loc('plain PDF');
                                       # loc('Plain PDF');
                                       format_name => 'Plain PDF',
                                       format_priority => 1,
                                      },
                           fields => {
                                      bb_format => 'pdf',
                                      bb_imposed => 0,
                                      bb_twoside => 0,
                                     },
                          },
                   a4_pdf => {
                              initial => {
                                          format_alias => 'a4.pdf',
                                          # loc('A4 imposed PDF');
                                          format_name => 'A4 imposed PDF',
                                          format_priority => 2,
                                          bb_signature_2up => '40-80',
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
                                          # loc('Letter imposed PDF');
                                          format_name => 'Letter imposed PDF',
                                          format_priority => 3,
                                          bb_signature_2up => '40-80',
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
                                          # loc('Slides (PDF)'),
                                          format_name => 'Slides (PDF)',
                                          format_priority => 4,
                                          },
                              fields => {
                                         bb_format => 'slides',
                                        },
                             },
                  );
    return %formats;
}

sub check_and_update_custom_formats {
    my $self = shift;
    my %formats = $self->fixed_formats_definitions;
    my $guard = $self->result_source->schema->txn_scope_guard;
    foreach my $method (sort keys %formats) {
        my $alias = $formats{$method}{initial}{format_alias} or die;

        my $cf = $self->custom_formats->find({ format_alias => $alias });
        unless ($cf) {
            my %insertion = %{$formats{$method}{initial}};
            $insertion{active} = 0;
            my @fixed;
            foreach  my $k (sort keys %{$formats{$method}{fields}}) {
                my $v = $formats{$method}{fields}{$k};
                $k =~ s/bb_//;
                push @fixed, "$k:$v";
            }
            $insertion{format_description} = "Standard format. Changes to these fields will be ignored: "
              . join(' ', @fixed);
            $cf = $self->custom_formats->create(\%insertion);
            # import the common stuff from the site
            $cf->sync_from_site;
        }
        die "Shouldn't happen" unless $cf;

        if ($self->$method) {
            if (!$cf->active) {
                log_info { "Activating CF " . $self->id . '/' . $cf->format_alias };
                $cf->update({ active => 1 });
            }
        }
        elsif ($cf->active) {
            if (!$self->$method) {
                log_info { "Setting $method flag for " . $self->id . '/' . $cf->format_alias };
                $self->update({ $method => 1 });
            }
        }
        else {
            log_info { "$method for " . $self->id . " is disabled" };
        }
        Dlog_debug { "Enforcing $_ on " . $cf->format_name } $formats{$method}{fields};
        $cf->update($formats{$method}{fields});
    }
    foreach my $cf ($self->custom_formats->all) {
        $cf->create_format_code;
    }
    $guard->commit;
}


sub known_langs {
    AmuseWikiFarm::Utils::Amuse::known_langs();
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

sub site_files {
    return shift->global_site_files->app_files;
}

sub thumbnails {
    return shift->global_site_files->thumbnails;
}

sub public_files {
    return shift->global_site_files->public_files;
}


sub index_site_files {
    my $self = shift;
    my $dir = Path::Tiny::path($self->path_for_site_files);
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->site_files->delete;
    $self->public_files->delete;
    if ($dir->exists) {
        foreach my $path ($dir->children(qr{^[a-z0-9]([a-z0-9-]*[a-z0-9])?\.[a-z0-9]+$})) {
            my ($w, $h) = AmuseWikiFarm::Utils::Amuse::image_dimensions($path);
            my $stored = $self->site_files->create({
                                                    file_name => $path->basename,
                                                    file_path => "$path",
                                                    image_width => $w,
                                                    image_height => $h,
                                                   });
        }
        if (my $pubdir = $dir->child('public')) {
            if ($pubdir->exists) {
                # be very tolerant with paths
                foreach my $path ($pubdir->children(qr{^\w})) {
                    $self->public_files->create({
                                                 file_path => "$path",
                                                 file_name => $path->basename,
                                                });
                }
            }
        }
    }
    $guard->commit;
    return $self->site_files->count;
}

sub has_site_file {
    my ($self, $file) = @_;
    if (my $gfile = $self->site_files->find({ file_name => $file })) {
        return $gfile->file_path;
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

has custom_category_types => (is => 'ro',
                              isa => 'ArrayRef',
                              lazy => 1,
                              builder => '_build_custom_category_types');

sub _build_custom_category_types {
    my $self = shift;
    my @out;
    foreach my $ct ($self->site_category_types->search(undef, { order_by => 'priority'})->all) {
        push @out, {
                    name => $ct->category_type,
                    fields => $ct->header_fields,
                   };
    }
    return \@out;
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
    return File::Spec->catdir(ROOT, $self->staging_dirname);
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

    # the first thing we do is to assign a path and create a revision in the db
    my $pubdate = str2time($params->{pubdate}) || time();
    my $pubdt = DateTime->from_epoch(epoch => $pubdate);
    if (!$self->no_autoassign_pubdate) {
        $params->{pubdate} = $pubdt->iso8601;
    }

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
    my $created = $self->titles->create($bogus);
    if ($params->{node_id}) {
        Dlog_debug { "Assigning text to nodes $_" } $params->{node_id};
        my @nodes = ref($params->{node_id}) ? (@{$params->{node_id}}) : ($params->{node_id});
        foreach my $id (@nodes) {
            if (my $node = $self->nodes->find($id)) {
                log_info { "Assigned " . $created->uri . " to node " . $node->uri };
                $created->add_to_nodes($node);
            }
            else {
                log_error { "node $id not found in site " . $self->id };
            }
        }
    }
    my $revision = $created->new_revision('force');

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
                              sku
                              source lang pubdate
                              publisher
                              isbn
                              rights
                              seriesname
                              seriesnumber
                             /) {
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
    my ($self, %args) = @_;
    return AmuseWikiFarm::Archive::Xapian->new(
                                               %args,
                                               code => $self->id,
                                               page => $self->pagination_size_search,
                                               locale => $self->locale,
                                               # disable stemming for search on multilang environment
                                               stem_search => !$self->multilanguage,
                                               show_deferred => $self->show_preview_when_deferred,
                                               enable_xapian_suggestions => !!$self->enable_xapian_suggestions,
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
        $collator->cmp($a->list_title // '', $b->list_title // '')
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
        $collator->cmp($a->sorting_fragments->[0], $b->sorting_fragments->[0]) or
          $a->sorting_fragments->[1] <=> $b->sorting_fragments->[1] or
          $collator->cmp($a->sorting_fragments->[2], $b->sorting_fragments->[2])
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
    my ($self, $files, $logger, %opts) = @_;
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
    my (@muses, @images);
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
            push @muses, $file;
        }
        else {
            push @images, $file;
        }
    }
    foreach my $file (@images, @muses) {
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
                my (@to_do, @to_clean);
                foreach my $cf (@active_cfs) {
                    if ($indexed->wants_custom_format($cf)) {
                        push @to_do, $cf;
                    }
                    else {
                        push @to_clean, $cf;
                    }
                }
                push @to_clean, @inactive_cfs;

                foreach my $cf (@to_clean) {
                    $logger->("Removed inactive format " . $cf->format_name . "\n")
                      if $cf->remove_stale_files($indexed);
                }
              CUSTOMFORMAT:
                foreach my $cf (@to_do) {
                    # the standard compilation nuked the standard formats, so we
                    # have to restore them, preserving the TS. Then we
                    # will rebuild them in the next job.
                    $cf->install_aliased_file($indexed);
                    next CUSTOMFORMAT if $opts{skip_custom_formats};
                    if ($cf->needs_compile($indexed)) {
                        my $job = $self->jobs->build_custom_format_add({
                                                                        id => $indexed->id,
                                                                        cf => $cf->custom_formats_id,
                                                                       });
                        $logger->("Scheduled generation of "
                                  . $indexed->full_uri . '.' . ($cf->valid_alias || $cf->extension)
                                  . " (" .  $cf->format_name .') as task number #'
                                  . $job->id . "\n");
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
    $self->store_rss_feed;
    my $now = DateTime->now;
    $self->update({ last_updated => $now })
}

sub generate_static_indexes {
    my ($self, $logger) = @_;
    $logger ||= sub { return };
    if ($self->jobs->pending->build_static_indexes_jobs->count) {
        log_debug { "Generation of static indexes already scheduled" };
        $logger->("Generation of static indexes already scheduled\n");
    }
    else {
        $self->jobs->build_static_indexes_add;
        log_debug { "Scheduled static indexes generation" };
        $logger->("Scheduled static indexes generation\n");
    }
}

sub list_files_for_mirroring {
    my $self = shift;
    my $cache = Path::Tiny::path($self->mirror_list_file);
    my $list;
    try {
        $list = JSON::MaybeXS::decode_json($cache->slurp)
    } catch {
        log_warn { "Failed to read cached mirror list $cache $_, refreshing" };
        $list = $self->store_file_list_for_mirroring;
    };
    return $list;
}

sub store_file_list_for_mirroring {
    my $self = shift;
    my $file = Path::Tiny::path($self->mirror_list_file);
    my $list = $self->get_file_list_for_mirroring;
    log_debug { "Writing mirror list into cache $file" };
    $file->spew(JSON::MaybeXS::encode_json($list));
    return $list;
}


sub get_file_list_for_mirroring {
    my ($self) = @_;
    my $root = Path::Tiny::path($self->repo_root);
    my $index_ts = (stat($root->child('index.html')))[9] || '';
    my @list = map { +{
                       file => $_,
                       ts => $index_ts,
                      } } ('index.html', 'titles.html', 'topics.html', 'authors.html' );
    my $root_as_string = $root->stringify;
    my $mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
    find({ wanted => sub {
               my $filename = $_;
               if (-f $filename) {
                   my $ts = (stat($filename))[9];
                   my ($volume, $dir, $file) = File::Spec->splitpath(File::Spec->abs2rel($filename,
                                                                                         $root_as_string));
                   my @fragments = grep { length($_) } (File::Spec->splitdir($dir), $file);

                   Dlog_debug { "$filename: $_" } \@fragments;
                   return if grep { !m{\A[0-9a-zA-Z_-]+(\.[0-9a-zA-Z]+)*\z} } @fragments;
                   if ($fragments[-1] =~ m/\.([0-9a-zA-Z]+)\z/) {
                       my $ext = $1;
                       if ($mime->{$ext}) {
                           push @list, {
                                        file => join('/', @fragments),
                                        ts => $ts,
                                       };
                       }
                       else {
                           log_debug { "$filename denied, $ext not allowed" };
                       }
                   }
               }
           },
           no_chdir => 1,
         }, map { $_->stringify } $root->children(qr{\A[0-9a-zA-Z][0-9a-zA-Z_-]*\z}));
    Dlog_debug { "List is $_" } \@list;
    return \@list;
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

    my $details = muse_file_info($file, $self->repo_root, {
                                                           category_types => $self->custom_category_types,
                                                           category_uri_use_unicode => $self->category_uri_use_unicode,
                                                          });
    Dlog_debug { "Details are $_"  } $details;
    # unparsable
    return unless $details;

    my $class  = $details->{f_class};
    die "Missing class!" unless $class;

    my %handled = (
                   image => 1,
                   upload_pdf => 1,
                   special => 1,
                   special_image => 1,
                   upload_binary => 1,
                   text => 1,
                  );

    die "Unknown class $class" unless $handled{$class};

    if ($class eq 'upload_pdf' or
        $class eq 'image' or
        $class eq 'upload_binary' or
        $class eq 'special_image') {
        $logger->("Inserting data for attachment $file and generating thumbnails\n");
        my $attachment =  $self->attachments->update_or_create($details);
        return $attachment if $class eq $attachment;
        try {
            $attachment->generate_thumbnails;
        } catch {
            my $err = $_;
            Dlog_error { "Error generating thumbnails for $_" } $details;
        };
        return $attachment;
    }
    else {
        delete $details->{mime_type};
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
    $insertion{blob_container} = delete $details->{blob} ? 1 : 0;

    # this is needed because we insert it from title, and DBIC can't
    # infer the site_id from there (even if it should, but hey).
    my @parsed_cats;
    if ($insertion{parent}) {
        if (delete $details->{parsed_categories}) {
            $logger->("Ignored categories, this is a child text\n");
        }
    }
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

    if ($class eq 'text') {
        # update the text structure
        $title->text_html_structure(1);
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
    $title->update_included_files($logger);
    $title->scan_and_store_links($logger) if $self->enable_backlinks;
    if (my $teaser_length = $self->automatic_teaser) {
        $title->autogenerate_teaser($teaser_length, $logger);
    }

    foreach my $att (grep { $_ } ($title->attached_objects, $title->cover_file, $title->images)) {
        unless ($title->title_attachments->find({ attachment_id => $att->id })) {
            $title->add_to_attachments($att);
        }
    }
    $guard->commit;

    # postpone the xapian indexing to the very end. The only piece
    # missing is the collation indexing, which changes anyway.

    $self->xapian->index_text($title, $logger);
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

sub mirror_list_file {
    my $self = shift;
    return File::Spec->catfile($self->path_for_site_files, "mirror.json");
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
    my @locales = sort keys %out;
    return @locales;
}

sub category_types_navbar_display {
    my ($self, $logged_in) = @_;
    my @out;
    foreach my $ct ($self->site_category_types->active->all) {
        my $type = $ct->category_type;
        # special case, already listed
        if ($type eq 'topic' and $self->fixed_category_list) {
            next;
        }
        if ($self->categories->by_type($ct->category_type)
            ->with_texts(deferred => $logged_in || $self->show_preview_when_deferred)
            ->first) {
            push @out, {
                        ctype => $ct->category_type,
                        title => $ct->name_plural,
                       };
        }
    }
    return \@out;
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
                  if ($relpath =~ m/\.muse$/) {
                      my $expected = AmuseWikiFarm::Utils::Amuse::get_corrected_path($relpath);
                      if ($expected and $expected ne $relpath) {
                          warn "Discarding $relpath, expected path is $expected\n";
                      }
                      else {
                          warn "Discarding $relpath, invalid path\n";
                      }
                  }
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

  INCLUSION:
    foreach my $included ($self->included_files) {
        my $path = Path::Tiny::path($included->file_path);
        if ($path->exists and $path->stat->mtime == $included->file_epoch) {
            log_debug { "Included file $path unchanged" };
            next INCLUSION
        }
        my $title = $included->title;
        my $relpath = File::Spec->catfile($title->f_archive_rel_path,
                                          $title->f_name . $title->f_suffix);
        if (exists $in_db->{$relpath}) {
            # signal that the file changed
            log_info { "Included file $path changed, bumping $relpath" };
            $in_db->{$relpath} = -1;
            my $parent = Path::Tiny::path($self->repo_root, $relpath);
            if ($parent->exists) {
                $parent->touch;
            }
            else {
                log_error { "$parent with included file $path does not exist!" };
            }
        }
        else {
            log_error { $self->id . " $relpath not found in the tracked files! (included $path)" };
        }
    }

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
        if ($remote =~ m/\A([a-z0-9]{2,30})\z/) {
            $remote = $1; # untainting tecnique from the old days
        }
        else {
            die "Invalid remote repo name $remote";
        }
        # cfr. git remote

        my $fatal;
        if ($action eq 'push') {
            eval {
                @out = $git->push($remote, 'master');
            };
            $fatal = $@;
        }
        elsif ($action eq 'pull') {
            eval {
                $git->fetch($remote);
                # safe interpolation, as we checked it.
                @out = $git->RUN(log => "HEAD..$remote/master");
                push @out, "\n";
                push @out, $git->pull({ ff_only => 1 }, $remote, 'master');
            };
            $fatal = $@;
        }
        else {
            die "Bad usage $action";
        }
        # this is the standard error was ->ERR, now is ->error
        if (my $err = $git->can('error') ? $git->error : $git->ERR) {
            push @out, @$err if @$err;
        }
        if ($fatal) {
            push @out, $fatal->error;
            log_error { $self->id . ": Fatal error on $action $remote: " . join("\n", @out) };
        }
    }
    else {
        push @out, "Not under git!";
    }
    if (@out) {
        Dlog_debug { "$_" } \@out;
        eval {
            my @decoded = map  { Encode::decode('UTF-8', $_) } @out;
            @out = @decoded;
        };
        my @lines;
        my $cgit_base_url = $self->cgit_base_url;
        foreach my $l (@out) {
            push @lines, $l . "\n";
            if ($l =~ m/^commit ([0-9a-f]+)$/) {
                push @lines, "URL: " . $cgit_base_url . "/commit/?id=" . $1 . "\n";
            }
        }
        @out = @lines;
        if ($logger) {
            $logger->(@out);
        }
        else {
            print @out;
        }
    }
    return @out;
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
    $self->scan_and_remove_rogue_symlinks;
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
    $self->index_site_files;
    eval {
        if (my @generated =
            AmuseWikiFarm::Utils::LexiconMigration::convert($self->lexicon,
                                                            $self->locales_dir)) {
            $logger->("Updated files from lexicon file\n");
        }
    };
    if ($@) {
        $logger->("Exception migrating lexicon to PO: $@");
    }
    $self->sync_remote_repo;
    my (@muses, @images);
    foreach my $f (sort @{ $todo->{new} }, @{ $todo->{changed} }) {
        if ($f =~ m/\.muse$/) {
            push @muses, $f;
        }
        else {
            push @images, $f;
        }
    }
    my @files = (@images, @muses);
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
    my $git = Git::Wrapper->new($root);
    return $git;
}

sub remote_repo_root {
    my $self = shift;
    return unless $self->repo_is_under_git;
    return Path::Tiny::path(ROOT, shared => repo => $self->id . '.git');
}

sub initialize_remote_repo {
    my ($self) = @_;
    my $target = $self->remote_repo_root;
    my $out;
    unless ($self->repo_is_under_git) {
        log_info { $self->id . ' is not under git' };
        return;
    }
    if (!$target->exists) {
        $target->mkpath;
        try {
            log_info { "Creating $target repo" };
            my $git = Git::Wrapper->new("$target");
            $git->init('--bare', '--shared=group');
            log_info { "Populating $target repo" };
            # add the nickname
            if ($self->remote_gits_hashref->{shared}) {
                # drop and redo
                log_info { "Resetting the shared remote" };
                $self->git->remote(qw/rm shared/);
            }
            $self->git->remote(add => shared => "$target");
            $self->git->push(shared => 'master');
            $out = $target;
        } catch {
            my $err = $_;
            log_error { "Cannot initialize $target: $err" } ;
        };
    }
    else {
        log_info { "Generating $target not needed" };
    }
    # populate the hook for the automatic pulling
    my $hook = Path::Tiny::path($target, hooks => 'post-receive');
    if (-d $hook->parent) {
        my $notify_url = $self->git_notify_url;
        my $cmd = sprintf("#!/bin/sh\nwget --tries=1 -q -O- %s || curl -s %s || echo 'Cannot notify site'\n",
                          $notify_url, $notify_url);
        # log_info { "Notify: $cmd" };
        my $existing = '';
        if ($hook->exists) {
            $existing = $hook->slurp_utf8;
        }
        Dlog_debug { "Existing is $_" } $existing;
        if ($existing ne $cmd) {
            if ($existing) {
                log_info { "Updated hook: $hook from $existing to $cmd" };
            }
            else {
                log_info { "Creating $hook: $cmd" };
            }
            # spew is atomic so the permissions need a refresh
            $hook->spew_utf8($cmd);
            $hook->chmod(0755);
        }
    }
    return $out;
}

sub archive_remote_repo {
    my $self = shift;
    if (my $target = $self->remote_repo_root) {
        my $backup = Path::Tiny::path(ROOT, shared => archive => 'archive-' . time()  . '-' . $self->id . '.git');
        $backup->parent->mkpath;
        if ($target->exists and !$backup->exists) {
            log_info {"Moving $target to $backup" };
            File::Copy::move("$target", "$backup");
            # blow the cgit cache as well
            my $schema = $self->result_source->schema;
            AmuseWikiFarm::Utils::CgitSetup->new(schema => $schema)->blow_cache;
            return $backup;
        }
        else {
            log_error { "Error archiving the remote repo: "
                          . " $target exists? " . ($target->exists ? 'yes' : 'no')
                          . " $backup exists? " . ($backup->exists ? 'yes' : 'no')
                      };
        }
    }
}

sub sync_remote_repo {
    my $self = shift;
    if (my $target = $self->remote_repo_root) {
        log_info { "Pushing to $target" };
        my $done;
        my $git = $self->git;
        # The logic here is simple: Either we can do a clean push, or
        # we archive the shared tree, redo the setup and notify the
        # move.

        try {
            $git->push(qw/shared master/);
            $done = 1;
        } catch {
            my $err = $_;
            log_error { "Normal push to $target failed: $err" };
        };
        return 1 if $done;
        try {
            log_info { "Archiving the tree then and redoing the setup" };
            if (my $backup = $self->archive_remote_repo) {
                $self->send_mail(git_conflict => {
                                                  to => $self->mail_notify,
                                                  from => $self->mail_from,
                                                  backup => "$backup",
                                                  shared => "$target",
                                                  subject => '[' . $self->canonical . "] git push shared master",
                                                 });
                $self->initialize_remote_repo;
                $done = 1;
            }
            else {
                log_error { "Cannot archive the remote repo :-/" };
            }
        } catch {
            my $err = $_;
            log_error { "Giving up on syncing $target: $err" };
        };
        return 1 if $done;
    }
}

sub shared_git {
    my $self = shift;
    if (my $root = $self->remote_repo_root) {
        if (-d $root) {
            return Git::Wrapper->new($root);
        }
    }
    return;
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
    if ($name =~ m/\A\s*([0-9a-zA-Z]{2,30})\s*\z/) {
        $valid_name = lc($1);
        log_debug { "Name is valid $valid_name" };
    }
    if ($url =~ m{\A\s*((git|https?):/(/[0-9a-zA-Z\._-]+)+/?)\s*\z}) {
        $valid_url = $1;
        log_debug { "URL is valid $valid_url" };
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
    my $remotes = $self->remote_gits_hashref;
    if (my $git_urls = $remotes->{$name}) {
        if ($git_urls->{fetch} and $git_urls->{fetch} =~ m{\A(git|https?)://}) {
            $git->remote(rm => $name);
            return 1;
        }
        else {
            Dlog_info { "Refusing to remove local git $name $_" } $git_urls;
        }
    }
    return;
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
                        allow_hostname_aliases   => 'option',
                        additional_nginx_conf    => 'option',

                        vhosts            => 'delete',

                        secure_site       => 'value',
                        secure_site_only  => 'value',
                        acme_certificate  => 'value',
                        ssl_key           => 'value_or_empty',
                        ssl_chained_cert  => 'value_or_empty',
                        ssl_cert          => 'value_or_empty',
                        ssl_ca_cert       => 'value_or_empty',
                        binary_upload_max_size_in_mega => 'value',
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
    my @booleans = (qw/logo_with_sitename
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

    # this needs validation
    {
        my @available_themes = $self->bootstrap_themes;
        foreach my $theme (qw/theme bootstrap_alt_theme/) {
            if (my $got = $params->{$theme}) {
                unless (grep { $_ eq $got } @available_themes ) {
                    push @errors, "$theme $got is invalid!";
                }
            }
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
                      sitename siteslogan logo mail_from
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
    $self->mail_notify('');
    if (my $mail_notify = delete $params->{mail_notify}) {
        if ($mail_notify =~ m/\@/) {
            $self->mail_notify(join(", ", map { $_->address } Email::Address->parse($mail_notify)));
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
                  bb_page_limit => [10, 8000],
                  binary_upload_max_size_in_mega => [1, 2000], # 2 giga seems fair
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
                           max_image_dimension
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

    foreach my $textarea (qw/robots_txt_override/) {
        my $value = delete $params->{$textarea} || '';
        $value =~ s/\r\n/\n/g;
        $value =~ s/^ +//gm;
        $value =~ s/ +$//gm;
        chomp $value;
        $value .= "\n";
        push @options, {
                        option_name => $textarea,
                        option_value => $value,
                       };
    }

    my @whitelist_ips = grep { $_ } split(/\s+/, delete $params->{whitelist_ips} || '');

    # this is totally arbitrary
    foreach my $option (qw/html_special_page_bottom use_luatex
                           allow_hostname_aliases
                           additional_nginx_conf
                           html_regular_page_bottom
                           left_layout_html
                           right_layout_html
                           top_layout_html
                           bottom_layout_html
                           footer_layout_html
                           do_not_enforce_commit_message
                           text_infobox_at_the_bottom
                           webchat_url
                           turn_links_to_images_into_images
                           enable_video_widgets
                           restrict_mirror
                           home_page
                           express_publishing
                           no_autoassign_pubdate
                           use_named_toc
                           layout_always_fluid
                           show_preview_when_deferred
                           lists_are_always_flat
                           titles_category_default_sorting
                           enable_order_by_sku
                           enable_backlinks
                           use_js_highlight
                           edit_option_page_left_bs_columns
                           edit_option_show_cheatsheet
                           edit_option_show_filters
                           edit_option_preview_box_height
                           show_type_and_number_of_pages
                           enable_xapian_suggestions
                           allow_binary_uploads
                           display_latest_entries_on_special
                           bootstrap_alt_theme
                           category_uri_use_unicode
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

    my @site_links;

    foreach my $spec ([ site_links => 'specials' ],
                      [ site_links_projects =>  'projects' ],
                      [ site_links_archive => 'archive' ]) {
        my $res = $self->deserialize_links(delete $params->{$spec->[0]}, $spec->[1]);
        if (@{$res->{errors}}) {
            push @errors, @{$res->{errors}};
        }
        else {
            push @site_links, @{$res->{links}};
        }
    }

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
        Dlog_info { "Updating links to $_" }
          +{
            from => [ map { +{ url => $_->url,
                               label => $_->label,
                               sorting_pos => $_->sorting_pos
                             } } $self->site_links ],
            to => \@site_links,
           };
        $self->site_links->delete;
        foreach my $link (@site_links) {
            $self->site_links->create($link);
        }

        Dlog_info { "Updating whitelist $_" }
          +{
            from => [ map { $_->ip } $self->whitelist_ips->editable ],
            to => \@whitelist_ips,
           };
        $self->whitelist_ips->editable->delete;
        foreach my $ip (@whitelist_ips) {
            $self->add_to_whitelist_ips({
                                         ip => $ip,
                                         user_editable => 1,
                                        }) unless $self->whitelist_ips->find({ ip => $ip });
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
    }
    # in any case discard the changes
    $self->discard_changes;
    @errors ? return join(" / ", @errors) : return;
}

sub configure_cgit {
    my $self = shift;
    $self->initialize_remote_repo;
    my $schema = $self->result_source->schema;
    my $cgit = AmuseWikiFarm::Utils::CgitSetup->new(schema => $schema);
    $cgit->configure;
}

sub get_git_token {
    my $self = shift;
    my $token = $self->git_token;
    unless ($token) {
        $token = Bytes::Random::Secure->new(NonBlocking => 1)
          ->string_from('AABCDEEFGHLMNPQRSTUUVWYZ123456789', 16);
        $self->git_token($token);
        $self->update;
    }
    return $token;
}

sub git_notify_url {
    my $self = shift;
    return $self->canonical_url . '/git-notify/' . $self->get_git_token;
}


sub deserialize_links {
    my ($self, $string, $menu) = @_;
    my (@links, @errors);
    my $order = 0;
    foreach my $line (grep { $_ } split(/\r?\n/, $string || '')) {
        if ($line =~ m{^\s*(\S+)\s+(.*?)\s*$}) {
            push @links, {
                          url => $1,
                          label => $2,
                          sorting_pos => $order++,
                          menu => $menu,
                         };
        }
        else {
            push @errors, "Invalid $menu link line $line";
        }
    }
    return { links => \@links, errors => \@errors };
}

sub serialize_links {
    my ($self, $menu) = @_;
    my $links = $self->site_links->search({ menu => $menu },
                                          { order_by => [qw/sorting_pos label url/] });
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

sub cgit_base_url {
    my $self = shift;
    return $self->canonical_url . '/git/' . $self->id;
}

sub all_site_hostnames {
    my $self = shift;
    my @hostnames = ($self->canonical);
    push @hostnames, $self->alternate_hostnames;
    return @hostnames;
}

sub all_site_hostnames_for_renewal {
    my $self = shift;
    # exclude pseudo top level domanis
    my @hostnames = grep { !/\.(exit|i2p|onion)\z/ } $self->all_site_hostnames;
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

sub webchat_url {
    return shift->get_option('webchat_url');
}

sub turn_links_to_images_into_images {
    return shift->get_option('turn_links_to_images_into_images') || '';
}

sub restrict_mirror {
    return shift->get_option('restrict_mirror') || '';
}

sub home_page {
    return shift->get_option('home_page') || '';
}

sub enable_video_widgets {
    return shift->get_option('enable_video_widgets') || '';
}

sub lists_are_always_flat {
    return shift->get_option('lists_are_always_flat') || '';
}

sub max_image_dimension {
    return shift->get_option('max_image_dimension') || 4000;
}

sub pagination_needed {
    my ($self, $count) = @_;
    return 0 unless $count;
    my $min = $self->paginate_archive_after;
    $count > $min ? return 1 : return 0;
}


sub update_option_value {
    my ($self, $option, $value) = @_;
    die "Missing option name" unless $option;
    my %reserved = (id => 1,
                    mode => 1,
                    last_updated => 1);
    die "$option is reserved, please use the admin panel" if $reserved{$option};
    my %columns = map { $_ => !$reserved{$_} } $self->columns;
    if ($columns{$option}) {
        $self->update({ $option => $value });
    }
    else {
        $self->site_options->update_or_create({
                                               option_name => $option,
                                               option_value => $value,
                                              });
    }
    return $self->get_from_storage;
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

sub use_named_toc {
    return shift->get_option('use_named_toc') || '';
}

sub layout_always_fluid {
    return shift->get_option('layout_always_fluid' || '');
}

sub no_autoassign_pubdate {
    return shift->get_option('no_autoassign_pubdate') || '';
}

sub express_publishing {
    return shift->get_option('express_publishing') || '';
}

sub html_special_page_bottom {
    return shift->get_option('html_special_page_bottom') || '';
}

sub html_regular_page_bottom {
    return shift->get_option('html_regular_page_bottom') || '';
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

sub footer_layout_html {
    return shift->get_option('footer_layout_html') || '';
}

sub display_latest_entries_on_special {
    return shift->get_option('display_latest_entries_on_special') // 1;
}

sub category_uri_use_unicode {
    return shift->get_option('category_uri_use_unicode') || '';
}

sub titles_available_sortings {
    my $self = shift;
    return $self->titles->available_sortings(
                                             sku => $self->enable_order_by_sku,
                                             text_size => $self->show_type_and_number_of_pages,
                                            );
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

sub enable_xapian_suggestions {
    my $self = shift;
    return $self->get_option('enable_xapian_suggestions') || '';
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

sub allow_hostname_aliases {
    shift->get_option('allow_hostname_aliases') ? 1 : 0;
}

sub additional_nginx_conf {
    shift->get_option('additional_nginx_conf');
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

sub mail_from_default {
    my $self = shift;
    if (my $mail = $self->mail_from) {
        return $mail;
    }
    else {
        return 'noreply@' . $self->canonical;
    }
}

sub allow_binary_uploads {
    shift->get_option('allow_binary_uploads') || '';
}

sub known_file_extensions {
    my $mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
    return join(' ', sort keys %$mime);
}

sub allowed_upload_extensions {
    my $self = shift;
    my $mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
    my @exts = grep { $mime->{$_} } split(/\s+/, $self->allow_binary_uploads);
    return @exts;
}

sub allowed_binary_uploads {
    my ($self, %options) = @_;
    my $mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
    my %allowed;
    foreach my $ext (qw/png jpg pdf/) {
        $allowed{$mime->{$ext}} = $ext or die "Shouldn't happen";
    }
    if (!$options{restricted} and $self->allow_binary_uploads) {
        foreach my $ext ($self->allowed_upload_extensions) {
            if (my $mime_type = $mime->{$ext}) {
                $allowed{$mime_type} ||= $ext;
            }
        }
    }
    Dlog_debug { "Allowed mime_types: $_"} \%allowed;
    return \%allowed;
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

    foreach my $spec ($self->result_source->resultset->site_serialize_related_rels) {
        my ($method, @search_args) = @$spec;
        my @records;
      ROW:
        foreach my $row ($self->$method->search(@search_args)->all) {
            my %row_data = _columns_with_no_embedded_id($row);
            if ($method eq 'categories') {
                # add the description, if needed
                my @descriptions;
                foreach my $desc ($row->category_descriptions) {
                    my %hashref = _columns_with_no_embedded_id($desc);
                    push @descriptions, \%hashref;
                }
                if (@descriptions) {
                    $row_data{category_descriptions} = \@descriptions;
                }
            }
            push @records, \%row_data;
        }
        if (my $ordering = $search_args[1]{order_by}) {
            if (@$ordering == 1) {
                my $order_by = $ordering->[0];
                log_debug { "Ordering again by $order_by" };
                @records = sort { $a->{$order_by} cmp $b->{$order_by} } @records;
            }
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
    # and the nodes
    $data{nodes} = [ map { $_->serialize } $self->nodes->sorted->all ];

    #and the attachments
    $data{attachments} = [ map { +{
                                   uri => $_->uri,
                                   title_muse => $_->title_muse,
                                   comment_muse => $_->comment_muse,
                                   title_html => $_->title_html,
                                   comment_html => $_->comment_html,
                                  } } $self->attachments->with_descriptions->all ];
    return \%data;
}

sub _validate_attached_uris {
    my ($self, $string) = @_;
    my @list = ref($string)
          ? (@$string)
          : (grep { length($_) } split(/\s+/, $string));
    my $titles_rs = $self->titles;
    my $cats_rs = $self->categories;
    my (@done, @missing);
  STRING:
    foreach my $str (@list) {
        if (my $title = $titles_rs->by_full_uri($str)) {
            push @done, $str;
        }
        elsif (my $cat = $cats_rs->by_full_uri($str)) {
            push @done, $str;
        }
        else {
            push @missing, $str;
        }
    }
    return +{
             ok => \@done,
             fail => \@missing,
            };
}



sub deserialize_nodes {
    my ($self, $nodes) = @_;
    my $changed = $self->repo_find_changed_files;
    return unless @$nodes;

    my @fail;
    foreach my $node (@$nodes) {
        if (my $str = $node->{attached_uris}) {
            my $validate = $self->_validate_attached_uris($str);
            Dlog_debug { "$str => $_" } $validate;
            push @fail, @{$validate->{fail} || []};
        }
    }
    if (@fail) {
        Dlog_error { $self->id . " cannot import nodes because of $_ non existing URIs,"
                       . " please reimport after a bootstrap\n" } \@fail;
        print map { $_ . "\n" } @fail;
        print $self->id . " is missing the above attached URIs, please reimport after a boostrap\n";
        return;
    }
    my $guard = $self->result_source->schema->txn_scope_guard;
    $self->nodes->delete;
    foreach my $node (@$nodes) {
        $self->nodes->update_or_create_from_params({ %$node });
    }
    # here's the trick. We need to run it twice so the parents exist
    foreach my $node (@$nodes) {
        $self->nodes->update_or_create_from_params({ %$node });
    }
    $guard->commit;
    return scalar(@$nodes);
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
                     amusebaskerville
                     robotojournal
                     purplejournal

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
                     paper
                     sandstone
                     superhero
                     yeti
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

sub bootstrap_alt_theme {
    return shift->get_option('bootstrap_alt_theme');
}

sub xapian_reindex_all {
    my ($self, $logger) = @_;
    $logger ||= sub { return };
    my $xapian = $self->xapian;
    my $newdir;
    my $titles = $self->titles->texts_only;
    unless ($titles->count) {
        $xapian->write_specification_file;
        return;
    }
    try {
        my $newdb = $self->xapian(auxiliary => 1);
        log_info { "Building new db against " . $newdb->xapian_dir };
        while (my $title = $titles->next) {
            $newdb->index_text($title, $logger);
        }
        $newdir = $newdb->xapian_dir;
        log_info { "new xapian dir is $newdir" };
    } catch {
        my $err = $_;
        log_error { "$err while rebuilding xapian index for " . $self->id };
    };
    if ($newdir and -d $newdir) {
        my $src = Path::Tiny::path($newdir);
        my $dest = Path::Tiny::path($xapian->xapian_dir);
        my $backup = Path::Tiny::path($xapian->xapian_backup_dir);
        log_info { "moving $dest to $backup and  $newdir to $dest" };
        try {
            $backup->remove_tree({ verbose => 1 }) if $backup->exists;
            # please note that this is not atomic, but it should be
            # really fast as it's a rename. I think we can afford a
            # couple of failed requests. At least for now.
            $dest->move($backup) if $dest->exists;
            $src->move($dest);
            $xapian->write_specification_file;
        } catch {
            my $err = $_;
            log_error { "$err while swapping xapian dbs for " . $self->id };
        };
    }
    else {
        log_error { "No newdir $newdir set for " . $self->id };
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
    my ($self, $locale_asked) = @_;
    log_debug { "Loading localizer" };
    # there is no caching here. This should be called only outside the
    # web app if needed.
    my $locale = $locale_asked || $self->locale || 'en';
    unless ($self->known_langs->{$locale}) {
        log_error { "Unknown locale asked: $locale, defaulting to en" };
        $locale = 'en';
    }
    require AmuseWikiFarm::Archive::Lexicon;
    return AmuseWikiFarm::Archive::Lexicon->new->localizer($locale,
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

sub send_mail {
    my ($self, $mkit, $tokens) = @_;
    foreach my $f (qw/to from cc/) {
        if (length($tokens->{$f})) {
            my $addresses = $tokens->{$f};
            # $addresses =~ s/\r?\n/,/g;
            if (my @addresses = Email::Address->parse($addresses)) {
                $tokens->{$f} = join(', ', map { $_->address } @addresses);
                log_debug { "Mail token $f is $tokens->{$f}" };
            }
            else {
                log_error { "Invalid email for $f $tokens->{$f} for $mkit" };
                $tokens->{$f} = '';
            }
        }
        else {
            # 0 or undef length
            $tokens->{$f} = '';
        }
    }
    return unless $tokens->{to} && $tokens->{from};

    # check if the recipient is known to us and have a language
    # preference

    if (my $known_user = $self->result_source->schema->resultset('User')
        ->search({
                  email => $tokens->{to},
                  preferred_language => [ keys %{$self->known_langs} ],
                 })->first) {
        $tokens->{lh} = $self->localizer($known_user->preferred_language);
    }
    else {
        $tokens->{lh} = $self->localizer;
    }
    $tokens->{list_id} = $self->id . '.' . $self->canonical;
    $self->mailer->send_mail($mkit => $tokens);
}

sub crawlable_opds_feed_file {
    my $self = shift;
    return Path::Tiny::path($self->path_for_site_files, 'opds-crawlable.xml');
}

sub get_crawlable_opds_feed {
    my $self = shift;
    my $file = $self->crawlable_opds_feed_file;
    if ($file->exists) {
        return $file->slurp_utf8;
    }
    else {
        return;
    }
}

sub initialize_opds_feed {
    my ($self, $feed) = @_;
    $feed ||= XML::OPDS->new;
    my $prefix = $self->canonical_url;
    $feed->prefix($prefix);
    my $lh = $self->localizer;
    # add the favicon
    if ($self->has_site_file('favicon.ico')) {
        $feed->icon('/favicon.ico');
    }
    $feed->updated($self->last_updated || DateTime->now);
    $feed->author($self->sitename);
    $feed->author_uri($prefix);
    my %start = (
                 title => $self->sitename,
                 href => '/opds',
                );
    # populate the feed with the root
    $feed->add_to_navigations_new_level(%start);
    $start{rel} = 'start';
    $feed->add_to_navigations(%start);
    my @opds_links =  ({
                        href => '/opds/titles',
                        title => $lh->loc('Titles'),
                        description => $lh->loc('Full list of texts'),
                        acquisition => 1,
                       });
    foreach my $ct ($self->site_category_types->active->ordered->all) {
        push @opds_links, {
                           href => '/opds/category/' . $ct->category_type,
                           title => $lh->loc($ct->name_plural),
                           description => $lh->loc($ct->name_plural),
                          };
    }
    push @opds_links, ({
                        href => '/opds/new',
                        title => $lh->loc('New'),
                        description => $lh->loc('Latest entries'),
                        rel => 'new',
                        acquisition => 1,
                       },
                       {
                        href => '/opds/crawlable',
                        title => $lh->loc('Titles'),
                        description => $lh->loc('Full list of texts'),
                        rel => 'crawlable',
                        acquisition => 1,
                       },
                       {
                        href => '/opensearch.xml',
                        title => $lh->loc('Search'),
                        rel => 'search',
                       });
    foreach my $entry (@opds_links) {
        $feed->add_to_navigations(%$entry);
    }
    return $feed;
}

sub store_crawlable_opds_feed {
    my $self = shift;
    my $feed = $self->initialize_opds_feed;
    my $lh = $self->localizer;
    $feed->add_to_navigations_new_level(
                                        acquisition => 1,
                                        href => '/opds/crawlable',
                                        title => $lh->loc('Titles'),
                                        description => $lh->loc('Full list of texts'),
                                       );
    # This is as much optimized as it can get. The bottleneck now is
    # in the XML generation, and there is nothing to do, I think.
    my $texts_rs = $self->titles->published_texts->sort_by_pubdate_desc
      ->search(undef,
               {
                result_class => 'DBIx::Class::ResultClass::HashRefInflator',
                collapse => 1,
                join => { title_categories => 'category' },
                columns => [qw/me.uri
                               me.title
                               me.lang
                               me.date
                               me.pubdate
                               me.subtitle
                              /],,
                '+columns' => {
                               'title_categories.title_id' => 'title_categories.title_id',
                               'title_categories.category_id' => 'title_categories.category_id',
                               'title_categories.category.uri' => 'category.uri',
                               'title_categories.category.type' => 'category.type',
                               'title_categories.category.name' => 'category.name',
                              }
               });
    my $dt_parser = $self->result_source->schema->storage->datetime_parser;
    while (my $text = $texts_rs->next) {
        my %entry = (
                     title => AmuseWikiFarm::Utils::Amuse::clean_html($text->{title}),
                     href => '/library/' . $text->{uri},
                     epub => '/library/' . $text->{uri} . '.epub',
                     language => $text->{lang} || 'en',
                     issued => $text->{date} || '',
                     summary => AmuseWikiFarm::Utils::Amuse::clean_html($text->{subtitle}),
                     files => [ '/library/' . $text->{uri} . '.epub', ],
                    );
        if ($text->{pubdate}) {
            $entry{updated} = $dt_parser->parse_datetime($text->{pubdate});
        }
        if (my $cats = $text->{title_categories}) {
            foreach my $cat (@$cats) {
                if (my $category = $cat->{category}) {
                    if ($category->{type} eq 'author') {
                        $entry{authors} ||= [];
                        push @{$entry{authors}}, {
                                                  name => $category->{name},
                                                  uri => '/category/author/' . $category->{uri},
                                                 };
                    }
                }
            }
        }
        $feed->add_to_acquisitions(%entry);
    }
    $self->crawlable_opds_feed_file->spew_raw($feed->atom->as_xml);
}


sub rss_feed_file {
    my $self = shift;
    return Path::Tiny::path($self->path_for_site_files, 'rss.xml');
}

sub get_rss_feed {
    my $self = shift;
    my $file = $self->rss_feed_file;
    my $feed;
    try {
        $feed = $file->slurp_utf8;
    } catch {
        $feed = $self->store_rss_feed;
    };
    return $feed || '';
}

# same logic as the file list for mirroring. If called directly,
# create the feed and write the file. The writing here is atomical.

sub store_rss_feed {
    my $self = shift;
    my $feed = $self->create_feed;
    my $file = $self->rss_feed_file;
    $file->parent->mkpath;
    $file->spew_utf8($feed);
    return $feed;
}

sub feed_link {
    my $self = shift;
    return $self->canonical_url . '/feed';
}

sub create_feed {
    my $self = shift;
    my @texts = $self->latest_entries_for_rss_rs;
    my @specials = $self->titles->published_specials;
    my $feed = XML::FeedPP::RSS->new;
    my $lh = $self->localizer;
    # set up the channel
    $feed->title($self->sitename || $self->canonical_url);
    $feed->description($self->siteslogan);
    $feed->link($self->canonical_url);
    $feed->language($self->locale);
    $feed->xmlns('xmlns:atom' => "http://www.w3.org/2005/Atom");

    # set the link to ourself
    $feed->set('atom:link@href', $self->feed_link);
    $feed->set('atom:link@rel', 'self');
    $feed->set('atom:link@type', "application/rss+xml");

    if (@texts) {
        $feed->pubDate($texts[0]->pubdate->epoch);
    }

    foreach my $text (@specials, @texts) {
        my $pubdate_epoch = $text->pubdate->epoch;

        # to fool the scrapers, set the permalink for specials
        # adding a version with the timestamp of the file, so we
        # catch updates
        my $ts = $text->is_regular ? $pubdate_epoch : $text->f_timestamp_epoch;
        my $link = $self->canonical_url . $text->full_uri . "?v=$ts";

        my $item = $feed->add_item($link);
        $item->title(AmuseWikiFarm::Utils::Amuse::clean_html($text->author_title));
        $item->pubDate($pubdate_epoch);
        $item->guid(undef, isPermaLink => 1);

        my @lines;
        if ($text->is_regular) {
            foreach my $method (qw/author title subtitle date notes source/) {
                my $string = $text->$method;
                if (length($string)) {
                    push @lines,
                      '<strong>' . $lh->loc_html(ucfirst($method)) . '</strong>: ' . $string;
                }
            }
        }
        if (my $teaser = $text->teaser) {
            push @lines, '<div>' . $teaser . '</div>';
        }
        else {
            push @lines, '<div>' . $text->feed_teaser . '</div>';
        }
        $item->description('<div>' . join('<br>', @lines) . '</div>');
        # if we provide epub, add it as attachment, so the poor
        # bastards with phones can actually read something.
        if ($self->epub) {
            my $epub_local_file = $text->filepath_for_ext('epub');
            if (-f $epub_local_file) {
                my $epub_url = $self->canonical_url . $text->full_uri . '.epub';
                log_debug { "EPUB path = $epub_local_file" };
                $item->set('enclosure@url' => $epub_url);
                $item->set('enclosure@type' => 'application/epub+zip');
                $item->set('enclosure@length' => -s $epub_local_file);
            }
        }
    }
    return $feed->to_string;
}

sub robots_txt {
    my $self = shift;
    my $provided = $self->robots_txt_override;
    if ($provided =~ m/\w/) {
        return $provided;
    }
    else {
        return $self->robots_txt_default;
    }
}

sub robots_txt_default {
    my $self = shift;
    my $robots = <<"ROBOTS";
User-agent: *
Disallow: /edit/
Disallow: /bookbuilder/
Disallow: /bookbuilder
Disallow: /random
Disallow: /git/
ROBOTS
    $robots .= "Sitemap: " . $self->canonical_url . '/sitemap.txt' . "\n";
    if (!$self->restrict_mirror) {
        my $mirror_url = $self->canonical_url . '/mirror.txt';
        $robots .= <<"MIRROR";
# Istant mirror:
# wget -q -O - $mirror_url | wget -x -N -q -i -
MIRROR
    }
}

sub robots_txt_override {
    shift->get_option('robots_txt_override') || '';
}

sub init_category_types {
    my $self = shift;
    foreach my $ctype ({
                        category_type => 'author',
                        active => 1,
                        priority => 0,
                        name_singular => 'Author',
                        name_plural => 'Authors',
                       },
                       {
                        category_type => 'topic',
                        active => 1,
                        priority => 1,
                        name_singular => 'Topic',
                        name_plural => 'Topics',
                       }) {
        $self->site_category_types->find_or_create($ctype);
    }
    $self->discard_changes;
}

sub edit_category_types_from_params {
    my ($self, $args) = @_;
    my %params = %$args;
    my $count = 0;
    my $changed = 0;
    my $guard = $self->result_source->schema->txn_scope_guard;
    foreach my $cc ($self->site_category_types->all) {
        $count++;
        my $code = $cc->category_type;
        foreach my $f (qw/active priority name_singular name_plural/) {
            my $cgi = $code . '_' . $f;
            if (exists $params{$cgi}) {
                $cc->$f($params{$cgi})
            }
            if ($cc->is_changed) {
                Dlog_info { "Updating $code $_" } +{ $cc->get_dirty_columns };
                $cc->update;
                $changed++;
            }
        }
    }
    if ($params{create} and $params{create} =~ m/\A[a-z]{1,16}\z/) {
        $self->site_category_types->find_or_create({
                                                    category_type => $params{create},
                                                    priority => $count + 1,
                                                    active => 1,
                                                    name_singular => ucfirst($params{create}),
                                                    name_plural => ucfirst($params{create} . 's'),
                                                   });
        $changed++;
    }
    $guard->commit;
    return $changed;
}

sub save_bb_cli {
    my $self = shift;
    my $bin = Path::Tiny::path($self->repo_root, 'bin');
    $bin->mkpath;
    foreach my $cf ($self->custom_formats->all) {
        my $exe = $bin->child('compile-' . $cf->code);
        my @cli = @{ $cf->bookbuilder->as_cli({ as_arrayref => 1 }) };
        splice @cli, 1, 0, '--fontspec', "\$cwd/fontspec.json \\\n";
        $exe->spew_utf8(<<'EOF', join(' ', @cli), "\n");
#!/bin/sh

cwd=`pwd`
file=`dirname $1`/`basename $1 .muse`

if [ ! -f fontspec.json ]; then
    muse-create-font-file.pl fontspec.json
fi

EOF
        $exe->chmod(0755);
    }
    if (my $git = $self->git) {
        $git->add("$bin");
        # any change?
        if ($git->status->get('indexed')) {
            log_info { "Saving format definitions" };
            $git->commit({ message => "Updated format definitions" });
            $self->sync_remote_repo;
        }
    }

}

sub editable_whitelist_ips_rs {
    my $self = shift;
    my $rs = $self->whitelist_ips->editable;
    return $rs;
}

sub amuse_include_paths {
    my $self = shift;
    return [ grep { length $_ and -d $_ }
             map { $_->directory } $self->include_paths->search(undef, { order_by => 'sorting_pos' }) ];
}

sub scan_and_remove_rogue_symlinks {
    my $self = shift;
    my $git = $self->git;
    # no attack surface if no git.
    return unless $git;

    my $root = $self->repo_root;
    my $root_path = Path::Tiny::path($root)->realpath;
    my %symlinks;
    find({
          wanted => sub {
              my $file = $File::Find::name;
              if (-l $file) {
                  $symlinks{$file} = Path::Tiny::path($file)->realpath;
              }
          }
         }, $root);
    Dlog_debug { "Found symlinks: $_" } \%symlinks;

    my $removals = 0;
    foreach my $link (keys %symlinks) {
        my $target = $symlinks{$link};
        if ($root_path->subsumes($target)) {
            log_debug { "$link => $target is legit" };
        }
        else {
            log_info { "$link => $target needs to be removed, symlink outside the tree" };
            try {
                $git->rm($link);
                $removals++;
            }
            catch {
                my $err = $_;
                log_error { "Error removing $link => $target: $err" };
            };
        }
    }
    if ($removals) {
        $git->commit({ message => "Removed symlinks pointing outside the tree" });
        $self->sync_remote_repo;
    }
}

after insert => sub {
    my $self = shift;
    $self->discard_changes;
    $self->check_and_update_custom_formats;
    $self->init_category_types;
};

__PACKAGE__->meta->make_immutable;

1;
