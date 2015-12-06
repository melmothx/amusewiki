use utf8;
package AmuseWikiFarm::Schema::Result::Title;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Title

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
  default_value: (empty string)
  is_nullable: 0

=head2 subtitle

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 date

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 notes

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 source

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 list_title

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 author

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

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
  default_value: (empty string)
  is_nullable: 0

=head2 slides

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

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
  { data_type => "text", default_value => "", is_nullable => 0 },
  "subtitle",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "lang",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "date",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "notes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "source",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "list_title",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "author",
  { data_type => "text", default_value => "", is_nullable => 0 },
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
  { data_type => "text", default_value => "", is_nullable => 0 },
  "slides",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
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

=head2 categories

Type: many_to_many

Composing rels: L</title_categories> -> category

=cut

__PACKAGE__->many_to_many("categories", "title_categories", "category");


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2015-10-27 10:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YXo2Qg8Y7stNAS98QXiKhg

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


use File::Spec;
use Text::Amuse::Compile::Utils qw/read_file/;
use DateTime;
use File::Copy qw/copy/;
use AmuseWikiFarm::Log::Contextual;
use Text::Amuse;

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
    my $self = shift;
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
        warn "Changing status from $old_status to " . $self->status . "\n";
        $self->update;
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

    my $statusline = read_file($statusfile) || '';

    if ($statusline =~ m/^(OK|DELETED|FAILED)/) {
        my $status = $1;
        if ($status eq 'OK') {
            # nothing to do
        }
        elsif ($status eq 'DELETED') {
            warn "This should not happen! $statusline, but we're published!\n";
        }
        elsif ($status eq 'FAILED') {
            $self->deleted('Compilation failed!');
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
    my $self = shift;
    my $path = $self->filepath_for_ext('muse');
    my %factors = (
                   mk => 2,
                   ru => 2,
                  );
    if (-f $path) {
        my $size = -s $path;
        if (my $factor = $factors{$self->lang}) {
            $size = $size / $factor;
        }
        my $pages = sprintf('%d', $size / 2000);
        return $pages || 1;
    }
    else {
        return;
    }
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
    my $target_dir = File::Spec->catdir($self->site->staging_dir, $revision->id);
    if (-d $target_dir) {
        # mm, some db backend is reusing the ids, so clean it up
        opendir(my $dh, $target_dir) or die "Can't open dir $target_dir $!";
        my @cleanup = grep {
            -f File::Spec->catfile($target_dir, $_)
        } readdir($dh);
        closedir $dh;
        foreach my $clean (@cleanup) {
            log_warn { "Removing $clean in $target_dir\n" };
            unlink File::Spec->catfile($target_dir, $clean) or log_warn { "Cannot remove $target_dir/$clean $!" };
        }
    }
    else {
        mkdir $target_dir or  die "Couldn't create $target_dir $!";
    }
    my $fullpath = File::Spec->catfile($target_dir, $uri . '.muse');
    $revision->f_full_path_name($fullpath);

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
    my $self = shift;
    my $uri = $self->uri;
    my $class = $self->f_class;
    if ($class eq 'special') {
        return '/special/' . $uri;
    }
    elsif ($class eq 'text') {
        return '/library/' . $uri;
    }
    else {
        die "WTF";
    }
}

sub full_edit_uri {
    my $self = shift;
    return $self->full_uri . '/edit';
}

=head2 Attached pdf (#ATTACH directive)

=head2 attached_pdfs

Return an arrayref with the list of attached pdfs which are actually
stored in the tree and indexed in the db, or nothing.

=cut

sub attached_pdfs {
    my $self = shift;
    my $string = $self->attach;
    return unless $string;
    my @tokens = split(/[\s;,]+/, $string);
    my @indexed;
    foreach my $token (@tokens) {
        next unless $token;
        if ($self->site->attachments->by_uri($token)) {
            push @indexed, $token;
        }
    }
    @indexed ? return \@indexed : return;
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
    if ($site->cgit_integration && $site->repo_is_under_git) {
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

sub delete {
    my $self = shift;
    my @categories = $self->categories;
    # do the deletion
    my $exit = $self->next::method;
    foreach my $cat (@categories) {
        $cat->title_count_update;
    }
    return $exit;
}

sub muse_object {
    my $self = shift;
    return Text::Amuse->new(file => $self->f_full_path_name);
}

sub text_html_structure {
    my $self = shift;
    my $muse = $self->muse_object;
    my @toc = $muse->raw_html_toc;
    my $index = 0;
    my @out;
    while (@toc) {
        my $summary = shift @toc;
        my $data = {
                    title => $summary->{string},
                    index => $index++,
                    toc => $summary->{index},
                    padding => 1,
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
    return \@out;
}

__PACKAGE__->meta->make_immutable;
1;
