use utf8;
package AmuseWikiFarm::Schema::Result::Title;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Title - Texts metadata

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

=head1 TABLE: C<title>

=cut

__PACKAGE__->table("title");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  is_nullable: 1

=head2 subtitle

  data_type: 'text'
  is_nullable: 1

=head2 lang

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 date

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=head2 source

  data_type: 'text'
  is_nullable: 1

=head2 list_title

  data_type: 'text'
  is_nullable: 1

=head2 author

  data_type: 'text'
  is_nullable: 1

=head2 uid

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 attach

  data_type: 'text'
  is_nullable: 1

=head2 pubdate

  data_type: 'datetime'
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  default_value: 'unpublished'
  is_nullable: 0
  size: 16

=head2 parent

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 publisher

  data_type: 'text'
  is_nullable: 1

=head2 isbn

  data_type: 'text'
  is_nullable: 1

=head2 rights

  data_type: 'text'
  is_nullable: 1

=head2 seriesname

  data_type: 'text'
  is_nullable: 1

=head2 seriesnumber

  data_type: 'text'
  is_nullable: 1

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

=head2 deleted

  data_type: 'text'
  is_nullable: 1

=head2 slides

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 text_structure

  data_type: 'text'
  is_nullable: 1

=head2 cover

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 teaser

  data_type: 'text'
  is_nullable: 1

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 sku

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 text_qualification

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 text_size

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 attachment_index

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 blob_container

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", is_nullable => 1 },
  "subtitle",
  { data_type => "text", is_nullable => 1 },
  "lang",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "date",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
  "source",
  { data_type => "text", is_nullable => 1 },
  "list_title",
  { data_type => "text", is_nullable => 1 },
  "author",
  { data_type => "text", is_nullable => 1 },
  "uid",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "attach",
  { data_type => "text", is_nullable => 1 },
  "pubdate",
  { data_type => "datetime", is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "unpublished",
    is_nullable => 0,
    size => 16,
  },
  "parent",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "publisher",
  { data_type => "text", is_nullable => 1 },
  "isbn",
  { data_type => "text", is_nullable => 1 },
  "rights",
  { data_type => "text", is_nullable => 1 },
  "seriesname",
  { data_type => "text", is_nullable => 1 },
  "seriesnumber",
  { data_type => "text", is_nullable => 1 },
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
  "deleted",
  { data_type => "text", is_nullable => 1 },
  "slides",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "text_structure",
  { data_type => "text", is_nullable => 1 },
  "cover",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "teaser",
  { data_type => "text", is_nullable => 1 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "sku",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "text_qualification",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "text_size",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "attachment_index",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "blob_container",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
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

=head2 C<uri_f_class_site_id_unique>

=over 4

=item * L</uri>

=item * L</f_class>

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_f_class_site_id_unique", ["uri", "f_class", "site_id"]);

=head1 RELATIONS

=head2 included_files

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::IncludedFile>

=cut

__PACKAGE__->has_many(
  "included_files",
  "AmuseWikiFarm::Schema::Result::IncludedFile",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 mirror_info

Type: might_have

Related object: L<AmuseWikiFarm::Schema::Result::MirrorInfo>

=cut

__PACKAGE__->might_have(
  "mirror_info",
  "AmuseWikiFarm::Schema::Result::MirrorInfo",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 muse_headers

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::MuseHeader>

=cut

__PACKAGE__->has_many(
  "muse_headers",
  "AmuseWikiFarm::Schema::Result::MuseHeader",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 node_titles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::NodeTitle>

=cut

__PACKAGE__->has_many(
  "node_titles",
  "AmuseWikiFarm::Schema::Result::NodeTitle",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 revisions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::Revision>

=cut

__PACKAGE__->has_many(
  "revisions",
  "AmuseWikiFarm::Schema::Result::Revision",
  { "foreign.title_id" => "self.id" },
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

=head2 text_internal_links

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TextInternalLink>

=cut

__PACKAGE__->has_many(
  "text_internal_links",
  "AmuseWikiFarm::Schema::Result::TextInternalLink",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 text_months

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TextMonth>

=cut

__PACKAGE__->has_many(
  "text_months",
  "AmuseWikiFarm::Schema::Result::TextMonth",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 text_parts

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TextPart>

=cut

__PACKAGE__->has_many(
  "text_parts",
  "AmuseWikiFarm::Schema::Result::TextPart",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title_attachments

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAttachment>

=cut

__PACKAGE__->has_many(
  "title_attachments",
  "AmuseWikiFarm::Schema::Result::TitleAttachment",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title_categories

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleCategory>

=cut

__PACKAGE__->has_many(
  "title_categories",
  "AmuseWikiFarm::Schema::Result::TitleCategory",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 title_stats

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleStat>

=cut

__PACKAGE__->has_many(
  "title_stats",
  "AmuseWikiFarm::Schema::Result::TitleStat",
  { "foreign.title_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 attachments

Type: many_to_many

Composing rels: L</title_attachments> -> attachment

=cut

__PACKAGE__->many_to_many("attachments", "title_attachments", "attachment");

=head2 categories

Type: many_to_many

Composing rels: L</title_categories> -> category

=cut

__PACKAGE__->many_to_many("categories", "title_categories", "category");

=head2 monthly_archives

Type: many_to_many

Composing rels: L</text_months> -> monthly_archive

=cut

__PACKAGE__->many_to_many("monthly_archives", "text_months", "monthly_archive");

=head2 nodes

Type: many_to_many

Composing rels: L</node_titles> -> node

=cut

__PACKAGE__->many_to_many("nodes", "node_titles", "node");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-07-22 14:55:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:epoFFeSHNxWFi0ogIw3Xrg

=head2 translations

Resultset with the same Title class with the same C<uid> in the
header, excluding the caller.

=cut

__PACKAGE__->has_many(
    translations => "AmuseWikiFarm::Schema::Result::Title",
    sub {
        my $args = shift;
        return {
            "$args->{foreign_alias}.id"  => { '!=' => { -ident => "$args->{self_alias}.id" } },
            "$args->{foreign_alias}.uid" => { -ident => "$args->{self_alias}.uid",
                                              '!=' => ''},
        };
    },
    { cascade_copy => 0, cascade_delete => 0 },
   );


=head2 sibling_texts

Resultset with the same Title class with same C<site_id>, same
C<f_class> (C<text> or C<special> and same C<status>.

=cut

__PACKAGE__->has_many(sibling_texts => "AmuseWikiFarm::Schema::Result::Title",
                      sub {
                          my $args = shift;
                          return {
                                  "$args->{foreign_alias}.site_id" => {-ident => "$args->{self_alias}.site_id" },
                                  "$args->{foreign_alias}.f_class" => {-ident => "$args->{self_alias}.f_class" },
                                  "$args->{foreign_alias}.status"  => {-ident => "$args->{self_alias}.status"  },
                                 };
                      },
                      { cascade_copy => 0, cascade_delete => 0 });

__PACKAGE__->belongs_to(parent_text => "AmuseWikiFarm::Schema::Result::Title",
                        {
                         'foreign.uri' => 'self.parent',
                         'foreign.site_id' => 'self.site_id',
                         'foreign.f_class' => 'self.f_class',
                        },
                        {
                         join_type     => "LEFT",
                         is_foreign_key_constraint => 0,
                        });


__PACKAGE__->has_many(children_texts => "AmuseWikiFarm::Schema::Result::Title",
                      {
                       'foreign.parent' => 'self.uri',
                       'foreign.site_id' => 'self.site_id',
                       'foreign.f_class' => 'self.f_class',
                      },
                      { cascade_copy => 0, cascade_delete => 0 });

use File::Spec;
use Text::Amuse::Compile::Utils qw/read_file/;
use DateTime;
use File::Copy qw/copy/;
use AmuseWikiFarm::Log::Contextual;
use Text::Amuse;
use HTML::Entities qw/decode_entities encode_entities/;
use AmuseWikiFarm::Utils::Amuse qw/cover_filename_is_valid to_json from_json build_full_uri/;
use Path::Tiny qw//;
use HTML::LinkExtor; # from HTML::Parser
use HTML::TreeBuilder;
use URI;
use constant { PAPER_PAGE_SIZE => 2000 };

has selected_formats => (is => 'ro',
                         isa => 'Maybe[HashRef]',
                         lazy => 1,
                         builder => '_build_selected_formats',
                        );

sub _build_selected_formats {
    my $self = shift;
    if (my $formats = $self->muse_headers->header_value_by_name('formats')) {
        if ($formats =~ m/\w/) {
            my %out = map { $_ => 1 } split(/[,\s]+/, $formats);
            return \%out;
        }
    }
    return undef;
}

=head2 listing

The following methods return a string, which may be empty if no
related record is found.

=head3 author_list

Return a comma separated list of authors for the current text.

=head3 topic_list

Return a comma separated list of topics for the current text.

=head3 category_listing($type, $separator)

Return a string with the list of category of type $type (so far
<topic> or <author>) separated by $separator.

=head3 authors

A result set for related authors

=head3 topics

A result set for related topics

=cut

sub topics {
    return shift->categories->by_type('topic');
}

sub authors {
    return shift->categories->by_type('author');
}


sub topic_list {
    return shift->category_listing(topic => ', ');
}

sub author_list {
    return shift->category_listing(author => ', ');
}

sub category_listing {
    my ($self, $type, $sep) = @_;
    my @cats;
    my @results = $self->categories->by_type($type);
    foreach my $cat (@results) {
        push @cats, $cat->name;
    }
    @cats ? return join($sep, @cats) : return '';
}

=head2 Published text

Logic to determine if a file is published or not. These routine should
be called on indexing, not on searching, because they depend on the
current datetime. Only texts with a C<published> status should be
served directly.

Recognized statuses:

=over 4

=item deleted

File has been deleted

=item deferred

File has a publishing date in the future

=item published

File is up and running

=item editing

File is stashed in the staging area and should not be served. It will
have some revisions attached. The only real things set here are uri
and id. Everything else is bogus, and is used only to hook the
revisions, and prevent duplications and such.

=back

=head2 is_published

Return true when the status is set to C<published>

=head2 update_text_status

This method should be called only on indexing. It will check the
deleted column and the pubdate and update the status column.

=cut

sub update_text_status {
    my ($self, $logger) = @_;
    my $old_status = $self->status;
    if ($self->deleted) {
        $self->status('deleted');
    }
    elsif($self->pubdate->epoch > DateTime->now->epoch) {
        $self->status('deferred');
    }
    else {
        $self->status('published');
    }
    if ($self->is_changed) {
        my $msg = "Changing " . $self->uri . " status from $old_status to " . $self->status . "\n";
        if ($logger) {
            $logger->($msg);
        }
        else {
            warn $msg;
        }
        $self->update;
        eval {
            my $site = $self->site;
            $site->send_mail(publish => {
                                         to => $site->mail_notify,
                                         from => $site->mail_from,
                                         subject => $self->full_uri . ': ' . $self->status,
                                         url => $site->canonical_url . $self->full_uri,
                                         old_status => $old_status,
                                         new_status => $self->status,
                                         author_title => $self->author_title,
                                         pubdate => $self->pubdate_locale($site->locale),
                                        });
        };
        log_error { $@ } if $@;
    }
    $self->_check_status_file if $self->is_published;
    return;
}

sub _check_status_file {
    my $self = shift;
    # override if we find a status file, as we should
    my $statusfile = $self->filepath_for_ext('status');
    unless (-f $statusfile) {
        die "<$statusfile> not found!\n";
        return;
    }

    my ($statusline, @reasons) = Path::Tiny::path($statusfile)->lines_utf8;
    if ($statusline and $statusline =~ m/^(OK|DELETED|FAILED)/) {
        my $status = $1;
        if ($status eq 'OK') {
            # nothing to do
        }
        elsif ($status eq 'DELETED') {
            warn "This should not happen! $statusline, but we're published!\n";
        }
        elsif ($status eq 'FAILED') {
            $self->deleted(encode_entities(join('', grep { /\w/ } @reasons) || 'Compilation failed!',
                                           q{<>&"'}));
            $self->status('deleted');
            $self->update;
            warn "Compilation failed, setting status to deleted\n";
        }
        else {
            die "This shouldn't happen";
        }
    }
    else {
        warn "$statusfile is not parsable <$statusline>\n";
    }
}

sub is_published {
    return shift->status eq 'published';
}

sub is_regular {
    return shift->f_class eq 'text';
}


sub is_deferred {
    return shift->status eq 'deferred';
}

=head2 can_spawn_revision

Return true if the file exists in the tree, hence can be copied to the
staging area.

=head2 muse_file_exists_in_tree

Implementation and alias for C<can_spawn_revision>

=cut

sub muse_file_exists_in_tree {
    my $self = shift;
    if (-f $self->f_full_path_name) {
        return 1;
    }
    else {
        return 0;
    }
}


sub can_spawn_revision {
    return shift->muse_file_exists_in_tree;
}

=head2 File serving

=head3 filepath_for_ext($ext)

Given the extension (without the leading dot) as argument, return the
filename. It's not guaranteed to exist, though.

The method concatenates C<f_path>, C<f_name>, a dot and the extension,
using L<File::Spec>.


=cut

sub filepath_for_ext {
    my ($self, $ext) = @_;
    $ext ||= "html";
    die "Bad extension $ext" unless $ext =~ m/\A[a-z0-9]+(\.[a-z0-9]+)?\z/;
    return File::Spec->catfile($self->f_path,
                               $self->f_name . '.' . $ext);
}

sub check_if_file_exists {
    my ($self, $ext) = @_;
    die "Bad usage" unless $ext;
    if (-f $self->filepath_for_ext($ext)) {
        return 1;
    }
    else {
        return;
    }
}



=head3 html_body

Retrieve the bare HTML, if present.

=head3 muse_body

Retrieve the Muse source.

=cut

sub html_body {
    return shift->_get_body('bare.html');
}

sub muse_body {
    return shift->_get_body('muse');
}

sub _get_body {
    my ($self, $ext) = @_;
    die "Wrong usage" unless $ext;
    my $file = $self->filepath_for_ext($ext);
    return '' unless -f $file;
    my $text = read_file($file);
    return $text;
}

=head3 pages_estimated

Returns the expected page of output. We consider a page 2000 bytes.
This is not really true for cyrillic languages, so we double it for
them.

=cut

sub pages_estimated {
    my ($self, $length) = @_;
    unless (defined $length) {
        $length = $self->text_size;
    }
    return int(($length / PAPER_PAGE_SIZE) + 1);
}


=head2 new_revision($force)

Create a new revision for the current text. With an optional true
argument, skip the copying of the files. This is true when you're
creating a new revision from scratch, so the original file is not in
place.

=cut

sub new_revision {
    my ($self, $force) = @_;
    my $can_spawn = $self->can_spawn_revision;

    unless ($can_spawn || $force) {
        die "Can't create a revision from id: " . $self->id;
    }
    my $revision = $self->revisions->create({
                                             # help dbic to cope with this
                                             site_id => $self->site->id,
                                             updated => DateTime->now,
                                            });
    my $uri = $revision->title->uri;
    die "Couldn't find uri for belonging title!" unless $uri;
    my $rev_id = $revision->id;
    die "Should not happen" unless $rev_id;

    my $target_dir = Path::Tiny::path($self->site->staging_dir, $rev_id);
    if (-d $target_dir) {
        log_info { "Removing $target_dir, found existing when creating the revision\n" };
        $target_dir->remove_tree;
    }
    $target_dir->mkpath;
    my $fullpath = $target_dir->child($uri . '.muse');
    $revision->f_full_path_name("$fullpath");

    # copy the file twice. The first is the starting file, the second the
    # actual revision.

    if ($can_spawn) {
        copy($self->f_full_path_name, $revision->starting_file) or die $!;
        copy($self->f_full_path_name, $revision->f_full_path_name) or die $!;
    }

    # update and return a fresh copy
    $revision->update->discard_changes;
    return $revision;
}

=head2 URIs

WARNING! For practical and performance concerns, here we hardcode the
catalyst app url, instead of calling uri_for with 2 or 3 arguments

=cut

sub full_uri {
    my ($self, $uri) = @_;
    return build_full_uri({
                           class => 'Title',
                           f_class => $self->f_class,
                           uri => $uri || $self->uri,
                          });
}

sub base_path {
    my $self = shift;
    return build_full_uri({
                           class => 'Title',
                           f_class => $self->f_class,
                           uri => '',
                          });
}

sub full_edit_uri {
    my $self = shift;
    return $self->full_uri . '/edit';
}

sub full_header_api {
    my $self = shift;
    return $self->full_uri . '/json';
}

sub full_rebuild_uri {
    my $self = shift;
    return $self->full_uri . '/rebuild';
}

# emulated on Xapian
sub full_toc_uri {
    my $self = shift;
    return $self->full_uri . '/toc';
}

sub cover_file {
    my $self = shift;
    if (my $uri = $self->valid_cover) {
        if (my $att = $self->site->attachments->by_uri($uri)) {
            return $att;
        }
    }
    return undef;
}

sub cover_uri {
    my $self = shift;
    if (my $att = $self->cover_file) {
        return $att->full_uri;
    }
    return;
}

sub cover_thumbnail_uri {
    my $self = shift;
    if (my $att = $self->cover_file) {
        return $att->thumbnail_uri;
    }
    return;
}

sub cover_small_uri {
    my $self = shift;
    if (my $att = $self->cover_file) {
        return $att->small_uri;
    }
    return;
}

sub cover_large_uri {
    my $self = shift;
    if (my $att = $self->cover_file) {
        return $att->large_uri;
    }
    return;
}



=head2 Attached pdf (#ATTACH directive)

=head2 attached_pdfs

Return an arrayref with the list of attached pdfs which are actually
stored in the tree and indexed in the db, or nothing.

=cut

sub attached_objects {
    my $self = shift;
    my $string = $self->attach;
    return unless $string;
    my @tokens = split(/[\s;,]+/, $string);
    my @indexed;
    foreach my $token (@tokens) {
        next unless $token;
        if (my $att = $self->site->attachments->by_uri($token)) {
            push @indexed, $att;
        }
    }
    return @indexed;
}

sub images {
    my $self = shift;
    my $muse = $self->muse_object;
    my @out;
    foreach my $uri ($muse->attachments) {
        log_debug { "Found $uri" };
        if (my $att = $self->site->attachments->by_uri($uri)) {
            push @out, $att;
        }
    }
    return @out;
}

sub attached_pdfs {
    my $self = shift;
    my @all = $self->attached_objects;
    @all ? return [ map { $_->uri } @all ] : return;
}

=head2 in_tree_uri

Return the uri for the file, minus the extension, in the repo tree.
Needed by the static generator.

=cut

sub in_tree_uri {
    my $self = shift;
    my $relpath = $self->f_archive_rel_path;
    $relpath =~ s![^a-z0-9]!/!g;
    return join('/', '.', $relpath, $self->uri);

}

=head2 recent_changes_uri

Return the git link if there the site is setup for that

=cut

sub recent_changes_uri {
    my $self = shift;
    my $site = $self->site;
    if ($site->repo_is_under_git) {
        my $path = File::Spec->abs2rel($self->f_full_path_name,
                                       $site->repo_root);
        # probably we have to tweak this if running under windows, but
        # so far not a problem.
        my $site_id = $site->id;
        return "/git/$site_id/log/$path";
    }
    else {
        return;
    }
}

=head1 METHOD MODIFIERS

Delete method is overload to update the category text count.

=cut

before delete => sub {
    my $self = shift;
    log_debug { "Deleting " . $self->full_uri . " from xapian" };
    $self->site->xapian->delete_text($self);
};

sub muse_object {
    my $self = shift;
    if (my $file = $self->f_full_path_name) {
        if ( -f $file ) {
            return Text::Amuse->new(file => $file,
                                    include_paths => $self->site->amuse_include_paths,
                                   );
        }
    }
    return;
}

# never delete this, is called from an upgrade class.
sub text_html_structure {
    my ($self, $force) = @_;
    if ($force or !$self->text_parts->count) {
        eval {
            my $parts = $self->_parse_text_structure;
            Dlog_debug { "Retrieving text structure: $_" } $parts;
            my $order = 0;
            $self->text_parts->delete;
            my $total_size = 0;
            my $book = 0;
            foreach my $part (@$parts) {
                $part->{part_order} = $order++;
                $self->text_parts->create($part);
                $total_size += $part->{part_size};
                if ($part->{part_level} > 0 and
                    $part->{part_level} < 3) {
                    $book++;
                }
            }
            $self->update({
                           text_size => $total_size,
                           text_qualification => ($book ? 'book' : 'article'),
                           text_structure => '', # obsolete.
                          });
        };
        if ($@) {
            log_error { "$@ Failed to set text parts for " . $self->id };
        }
    }
    my @out = $self->text_parts->ordered->hri;
    return \@out;
}

sub _parse_text_structure {
    my ($self) = @_;
    my $muse = $self->muse_object;
    unless ($muse) {
        log_error { "Can't find file for text id " . $self->id };
        return [];
    }
    my @out = ({
                part_index => 'pre',
                part_level => 0,
                part_title => '',
                part_size => PAPER_PAGE_SIZE, # The first part is always a page.
                toc_index => 0,
               });

    # Text::Amuse doesn't care at all what it returns from
    # raw_html_toc. It just scans the pieces returned by as_splat_html
    # like this: for (my $i = 0; $i < @chunks; $i++) {
    # push @out, $chunks[$i] if $partials->{$i};
    # } so what we do here is the right thing.

    my $toc_index = 0;
    my $index = 0;
  HTMLPIECE:
    foreach my $piece ($muse->as_splat_html) {
        my $tree = HTML::TreeBuilder->new_from_content($piece);
        $tree->elementify;
        my %data = (part_index => $index++,
                    # add half a page for each section, to compensate
                    # for headers. This is an estimate, nothing
                    # critical here.
                    part_size => length($tree->as_text) + (PAPER_PAGE_SIZE / 2),
                   );

        # find the part_level and the part_title
        my ($first) = grep { ref($_) } $tree->look_down(_tag => 'body')->content_list;
        unless ($first) {
            log_info { "Can't find an element in $piece html from file: " . $self->f_full_path_name };
            next HTMLPIECE;
        }
        if ($first->tag =~ m/h([1-6])/) {
            $data{part_level} = $1 - 1;
            $data{part_title} = encode_entities($first->as_text, q{<>&"'});
            $data{toc_index} = ++$toc_index;
        }
        else {
            # this is a lonely initial element, so it's a special case
            die "This shouldn't happen! No headers should happen only at the beginning"
              unless $data{part_index} == 0;
            $data{part_level} = 0,
            $data{part_title} = $self->title;
            $data{toc_index} = 0;
        }

        # cleanup and push
        $tree->delete;
        push @out, \%data;
    }
    if ($self->notes || $self->source) {
        push @out, {
                    part_index => 'post',
                    part_level => 0,
                    part_title => '',
                    part_size => 0, # irrelevant
                    toc_index => 0,
                   };
    }
    return \@out;
}


sub _retrieve_text_structure {
    my $self = shift;
    # report the error if by chance we call this.
    log_error { "Calling _retrieve_text_structure is DEPRECATED" };
    my $muse = $self->muse_object;
    my @toc = $muse->raw_html_toc;
    my $index = 0;
    my @out = ({
                index => 'pre',
                padding => 1,
                highlevel => 1,
                level => 0,
               });
    while (@toc) {
        my $summary = shift @toc;
        my $data = {
                    title => $summary->{string},
                    index => $index++,
                    toc => $summary->{index},
                    padding => 1,
                    level => ($summary->{index} ? $summary->{level} : 0),
                   };
        if ($summary->{index}) {
            $data->{padding} += $summary->{level};
        }
        if ($data->{toc} && $data->{padding} < 4) {
            $data->{highlevel} = 1;
        }
        $data->{padding} *= 2;
        push @out, $data;
    }
    if ($self->notes || $self->source) {
        push @out, {
                    index => 'post',
                    padding => 1,
                    highlevel => 1,
                    level => 0,
                   };
    }
    return \@out;
}

=head2 sorted_categories($type)

Return a sorted list of categories where the type is argument.

To be used when prefetching the categories, when the query already was
executed.

=cut

sub sorted_categories {
    my ($self, $type) = @_;
    return sort { $a->sorting_pos <=> $b->sorting_pos }
      grep { $_->type eq $type } $self->categories->all;
}

sub opds_entry {
    my ($self) = @_;
    return unless $self->check_if_file_exists('epub');
    my %out = (
               title => $self->_clean_html($self->title),
               href => $self->full_uri,
               authors => [ map { +{ name => $_->name, uri => $_->full_uri } }
                            grep { $_->type eq 'author' } $self->categories->all ],
               epub => $self->full_uri . '.epub',
               language => $self->lang || 'en',
               issued => $self->date || '',
               updated => $self->pubdate,
               summary => $self->_clean_html($self->subtitle || ''),
               files => [ $self->full_uri . '.epub' ],
              );
    my @desc;
    if (my $teaser = $self->teaser) {
        push @desc, '<div>'. $self->teaser . '</div><div><br></div>';
    }

    if (my $image = $self->cover_uri) {
        $out{image} = $image;
        $out{thumbnail} = $self->cover_thumbnail_uri;
    }
    foreach my $method (qw/notes source/) {
        my $string = $self->$method;
        if (length($string)) {
            push @desc, '<div>' . $string . '</div>';
        }
    }
    if (@desc) {
        $out{description} = join("\n", @desc);
    }
    return \%out;
}

sub _clean_html {
    my ($self, $string) = @_;
    return "" unless defined $string;
    $string =~ s/<.+?>//g;
    return decode_entities($string);
}

sub pubdate_epoch {
    return shift->pubdate->epoch;
}

sub pubdate_locale {
    my ($self, $locale) = @_;
    $locale ||= 'en';
    my $dt = DateTime->from_object(object => $self->pubdate, locale => $locale);
    return $dt->format_cldr($dt->locale->date_format_medium);
}

sub insert_stat_record {
    my ($self, $type, $user_agent) = @_;
    my $now = DateTime->now;
    my $site_id = $self->site_id;
    $self->add_to_title_stats({
                               site_id => $site_id,
                               accessed => $now,
                               type => $type || '',
                               user_agent => $user_agent || '',
                              });
}

sub valid_cover {
    my $self = shift;
    return cover_filename_is_valid($self->cover);
}

sub monthly_archive {
    # it's a many to many, but someone should explain to me why it
    # would belong to more of them.
    return shift->monthly_archives->first;
}

sub newer_texts {
    my $self = shift;
    return $self->sibling_texts->newer_than($self->pubdate);
}

sub older_texts {
    my $self = shift;
    return $self->sibling_texts->older_than($self->pubdate);
}

sub newer_text {
    return shift->newer_texts->search(undef, { rows => 1 })->first;
}

sub older_text {
    return shift->older_texts->search(undef, { rows => 1 })->first;
}

sub path_tiny {
    return Path::Tiny::path(shift->f_full_path_name);
}

sub parent_dir {
    return shift->path_tiny->parent->stringify;
}

sub raw_headers {
    my $self = shift;
    my $all = $self->muse_headers;
    my %out;
    while (my $header = $all->next) {
        $out{$header->muse_header} = $header->muse_value;
    }
    return \%out;
}

sub backlinks {
    my $self = shift;
    return $self->site->text_internal_links
      ->by_uri_and_class($self->uri, $self->f_class)
      ->search_related(title => undef,
                       { distinct => 1 })
      ->status_is_published
      ->sorted_by_title;
}

sub scan_and_store_links {
    my ($self, $logger) = @_;
    if ($logger) {
        $logger->("Scanning links in " . $self->uri . "\n");
    }
    my $file = $self->filepath_for_ext('bare.html');
    my $site = $self->site;
    my %vhosts = map { $_->name => 1 } $site->vhosts;
    $vhosts{$site->canonical} = 1;
    my @uris;
    if (-f $file) {
        my $cb = sub {
            my($tag, %links) = @_;
            if ($tag eq 'a') {
                if (my $uri = $links{href}) {
                    if ($uri->can('host')) {
                        if (!$uri->host || $vhosts{$uri->host}) {
                            push @uris, $uri;
                        }
                    }
                }
            }
        };
        my $parser = HTML::LinkExtor->new($cb, $site->canonical_url . $self->base_path);
        $parser->parse_file($file);
    }
    else {
        log_error { "$file doesn't exist for link storing" };
    }

    # now we collected all the uris which reference titles in the same site.
    # null out existing
    $self->text_internal_links->delete;
    my %type_map = (
                    library => 'text',
                    special => 'special',
                   );
    foreach my $uri (@uris) {
        if ($uri->path =~ m/\A\/(library|special)\/([0-9a-z-]+)/) {
            my $text_uri = $2;
            my $f_class = $type_map{$1};
            unless ($f_class eq $self->f_class and
                    $text_uri eq $self->uri) {
                $self->add_to_text_internal_links({
                                                   site => $site,
                                                   f_class => $f_class,
                                                   uri => $text_uri,
                                                   full_link => "$uri",
                                                  });
            }
        }
    }
}

sub autogenerate_teaser {
    my ($self, $size, $logger) = @_;
    return if $size < 1;
    return if $self->teaser;
    log_debug { "Autogenerating teaser in " . $self->uri };
    $logger->("Generating teaser\n") if $logger;
    $self->update({ teaser => $self->_create_teaser($size) });
}

sub feed_teaser {
    my $self = shift;
    # eventually we can configure it. But 5000 chars is more than
    # enough for a feed.
    $self->_create_teaser(5000, base => $self->site->canonical_url . $self->base_path);
}

sub _create_teaser {
    my ($self, $size, %opts) = @_;
    die "Missing size" unless defined $size;
    my $file = Path::Tiny::path($self->filepath_for_ext('bare.html'));
    my $base = $opts{base} || $self->base_path;
    if ($file->exists) {
        my $tree = HTML::TreeBuilder->new_from_content($file->slurp_utf8);
        $tree->elementify;
        my $body = $tree->look_down(id => 'thework');
        teaser_cleanup_body($body);
        my $total = 0;
        my $ellipsed = 0;
        foreach my $child ($body->content_list) {
            if (ref $child) {
                if ($total > $size) {
                    $child->delete;
                    $ellipsed++;
                }
                else {
                    $total += length($child->as_text);
                }
            }
            else {
                $total += length($child);
            }
        }
        foreach my $links (@{ $body->extract_links }) {
            my ($link, $element, $attr, $tag) = @$links;
            $element->attr($attr => URI->new_abs($link, $base)->as_string) if $link ne '#';
        }
        if ($ellipsed) {
            $body->push_content([ p => '...', { class => 'amw-teaser-ellipsis' } ]);
        }
        else {
            # see amuse.js
            $body->push_content([ div => '', { class => 'amw-teaser-no-ellipsis' } ]);
        }
        log_debug { "Ellipsed $ellipsed nodes" };
        my $html = $body->as_HTML(q{<>&"'}, ' ', {});
        $tree->delete; # shouldn't be needed, but hey
        return $html;
    }
    else {
        return '';
    }
}

# recursive function to traverse all the tree
sub teaser_cleanup_body {
    my $elt = shift;
    $elt->normalize_content;
    # remove the ids.
    $elt->attr(id => undef);
    # remove internal linking
    if (my $href = $elt->attr('href')) {
        if ($href =~ m/\A#/) {
            $elt->attr(href => '#');
        }
    }
    # convert h to boldened divs
    if ($elt->tag =~ m/\Ah[1-6]\z/) {
        $elt->tag('div');
        $elt->attr(style => 'font-weight:bold');
    }
    foreach my $child ($elt->content_list) {
        if (ref $child) {
            teaser_cleanup_body($child);
        }
    }
}

sub author_title {
    my $self = shift;
    if (my $title = $self->title) {
        if (my $author = $self->author) {
            return $author . ' - ' . $title;
        }
        else {
            return $title;
        }
    }
    else {
        return $self->uri;
    }
}

sub date_year {
    my $self = shift;
    if (my $date = $self->date) {
        if ($date =~ m/\b([0-9]{4})\b/) {
            return $1;
        }
    }
    return;
}

sub date_decade {
    my $self = shift;
    if (my $year = $self->date_year) {
        $year = $year - ($year % 10);
        return $year;
    }
    else {
        return;
    }
}

sub page_range {
    my $self = shift;
    my $pages = $self->pages_estimated || 1;
    my @ranges = (1, 5, 10, 20, 30, 40, 50, 100, 150, 200, 300, 500, 1000);
    for (my $i = 0; $i < @ranges; $i++) {
        if ($pages < $ranges[$i]) {
            return $ranges[$i - 1] . '-' . $ranges[$i];
        }
    }
    return '+1000';
}

sub wants_custom_format {
    my ($self, $cf) = @_;
    die "Missing argument" unless $cf;
    die "Wrong argument" unless $cf->isa('AmuseWikiFarm::Schema::Result::CustomFormat');
    if (my $cfs = $self->selected_formats) {
        Dlog_debug { $self->full_uri . " has selected formats: $_ checking against " . $cf->code } $cfs;
        return $cfs->{$cf->code};
    }
    else {
        # nothing selected, so yes.
        return 1;
    }
}

sub display_categories {
    my $self = shift;
    my @out;

    my $text = $self;
    my $iterations = 0;
  PARENT:
    while (my $p = $text->parent_text) {
        $text = $p;
        $iterations++;
        if ($iterations > 10) {
            log_error { "Possible parentage with infinite recursion on " . $self->full_uri };
            last PARENT;
        }
    }
    foreach my $ctype ($self->site->site_category_types->active->all) {
        my $rs = $text->categories->by_type($ctype->category_type)->with_active_flag_on;
        my @list;
        while (my $cat = $rs->next) {
            push @list, {
                         uri => $cat->full_uri,
                         name => $cat->name,
                        };
        }
        if (@list) {
            push @out, {
                        # loc('Authors'); loc('Author'); loc('Topic'); loc('Topics');
                        title => @list > 1 ? $ctype->name_plural : $ctype->name_singular,
                        entries => \@list,
                        # s if for the legacy
                        identifier => $ctype->category_type . 's',
                        code => $ctype->category_type,
                       };
        }
    }
    return \@out;
}

sub update_included_files {
    my ($self, $logger) = @_;
    my $muse = $self->muse_object;
    $self->included_files->delete;
    log_debug { "Updating included files" };
    foreach my $f ($muse->included_files) {
        log_debug { "Parsing $f" };
        if ($f and -f $f) {
            eval {
                my $file = Path::Tiny::path($f);
                my $epoch = $file->stat->mtime;
                my $dt = DateTime->from_epoch(epoch => $epoch, time_zone => 'UTC');
                $self->add_to_included_files({
                                              site_id => $self->site_id,
                                              file_path => $f,
                                              file_epoch => $epoch,
                                              file_timestamp => $dt,
                                             });
            };
            if ($@) {
                log_error { "Failure parsing $f in " . $self->filepath_for_ext('muse') . ": $@" };
            }
        }
        else {
            log_error { "Included file $f in " . $self->filepath_for_ext('muse') . "is empty or does not exist?" };
        }
    }
}

sub is_gone {
    my $self = shift;
    if ($self->deleted) {
        if (!$self->site->redirections->search({
                                                type => $self->f_class,
                                                uri => $self->uri,
                                               })->count) {
            return 1;
        }
    }
    return 0;
}

sub mirror_manifest {
    my $self = shift;
    $self->result_source->resultset->by_id($self->id)->mirror_manifest;
}

__PACKAGE__->meta->make_immutable;

1;
