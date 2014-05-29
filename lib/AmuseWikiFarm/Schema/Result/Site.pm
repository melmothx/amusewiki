use utf8;
package AmuseWikiFarm::Schema::Result::Site;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Site

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
  size: 8

=head2 mode

  data_type: 'varchar'
  default_value: 'blog'
  is_nullable: 0
  size: 16

=head2 locale

  data_type: 'varchar'
  default_value: 'en'
  is_nullable: 0
  size: 3

=head2 magic_question

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 magic_answer

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

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
  is_nullable: 1
  size: 32

=head2 mail

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 canonical

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 sitegroup

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 bb_page_limit

  data_type: 'integer'
  default_value: 1000
  is_nullable: 0

=head2 tex

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 pdf

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 a4_pdf

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 lt_pdf

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 html

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 bare_html

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 epub

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 zip

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 ttdir

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 1024

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
  default_value: 'Linux Libertine O'
  is_nullable: 0
  size: 255

=head2 twoside

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 8 },
  "mode",
  {
    data_type => "varchar",
    default_value => "blog",
    is_nullable => 0,
    size => 16,
  },
  "locale",
  { data_type => "varchar", default_value => "en", is_nullable => 0, size => 3 },
  "magic_question",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "magic_answer",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "fixed_category_list",
  { data_type => "text", is_nullable => 1 },
  "sitename",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "siteslogan",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "theme",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "logo",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "mail",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "canonical",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "sitegroup",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "bb_page_limit",
  { data_type => "integer", default_value => 1000, is_nullable => 0 },
  "tex",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "pdf",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "a4_pdf",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "lt_pdf",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "html",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "bare_html",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "epub",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "zip",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "ttdir",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 1024 },
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
    default_value => "Linux Libertine O",
    is_nullable => 0,
    size => 255,
  },
  "twoside",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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

=head2 users

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::User>

=cut

__PACKAGE__->has_many(
  "users",
  "AmuseWikiFarm::Schema::Result::User",
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-05-28 22:42:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H8hvOzMEJ4dvYs2WNnYUSw

=head2 other_sites

Other sites with the same sitegroup id.

=cut

__PACKAGE__->has_many(
                      "other_sites",
                      "AmuseWikiFarm::Schema::Result::Site",
                      { "foreign.sitegroup" => "self.sitegroup" },
                      { cascade_copy => 0, cascade_delete => 0 },
                     );

use File::Spec;
use Cwd;
use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_file_info
                                   muse_filepath_is_valid
                                   muse_naming_algo/;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
use Text::Amuse::Compile;
use Date::Parse;
use DateTime;
use File::Copy qw/copy/;
use AmuseWikiFarm::Archive::Xapian;
use Unicode::Collate::Locale;
use File::Find;
use File::Basename qw/fileparse/;


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

=head2 compile_extra_options

Options to feed the extra key of the Text::Amuse::Compile object.

=head2 available_formats

Return a list of format => enable pairs.

=head2 available_text_exts

As above, but instead of the compiler options, list the extensions.

=cut

sub compile_options {
    my $self = shift;
    my %opts = $self->available_formats;

    if (my $dir = $self->ttdir) {
        $opts{ttdir} = $dir;
    }
    my %extra;
    foreach my $ext (qw/sitename siteslogan logo
                        papersize division fontsize
                        bcor mainfont twoside/) {
        $opts{extra}{$ext} = $self->$ext;
    }
    $opts{extra}{site} = $self->canonical;
    return %opts;
}

sub available_formats {
    my $self = shift;
    my %formats;
    foreach my $f (qw/tex pdf a4_pdf lt_pdf html bare_html epub zip/) {
        $formats{$f} = $self->$f;
    }
    return %formats;
}

sub available_text_exts {
    my $self = shift;
    my %formats = $self->available_formats;
    my %exts;
    foreach my $k (keys %formats) {
        my $ext = $k;
        $ext =~ s/_/./g;
        $ext = '.' . $ext;
        $exts{$ext} = $formats{$k};
    }
    return %exts;
}

sub known_langs {
    my $self = shift;
    return { ru => 'Русский',
             sr => 'Srpski',
             hr => 'Hrvatski',
             mk => 'Македонски',
             fi => 'Suomi',
             es => 'Español',
             en => 'English',
           };
}

# TODO special

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

=head2 repo_is_under_git

Return true if the site repo is kept under git.

=cut

sub repo_is_under_git {
    my $self = shift;
    return -d File::Spec->catdir($self->repo_root, '.git');
}

=head1 Site modes

To check the site mode, you should use these methods, instead of
looking at C<mode>.

The filtered actions boil down to editing and publishing, where
editing is also the creation of new texts.

=cut

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
    elsif ($title) {
        $uri = muse_naming_algo("$author $title");
    }
    unless ($uri) {
        return undef, "Couldn't generate the uri!";
    }
    # and store it in the params
    $params->{uri} = $uri;

    if ($self->titles->find({ uri => $uri })) {
        return undef, "Such an uri already exists";
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
                 pubdate => $pubdate,
                 f_suffix => '.muse',
                 status => 'editing',
                 f_class => $f_class,
                };

    foreach my $f (qw/f_path f_archive_rel_path f_timestamp
                      f_full_path_name f_name/) {
        $bogus->{$f} = '';
    }

    my $revision = $self->titles->create($bogus)->new_revision(1);
    my $file = $revision->f_full_path_name;
    die "full path was not set!" unless $file;

    # save a copy of the html request
    my $html_copy = File::Spec->catfile($revision->original_html);

    $params->{textbody} //= "\n";
    $params->{textbody} =~ s/\r//g;
    open (my $fhh, '>:encoding(utf-8)', $html_copy)
      or die "Couldn't open $html_copy $!";
    print $fhh $params->{textbody};
    print $fhh "\n";
    close $fhh or die $!;

    # populate the file with the parameters
    open (my $fh, '>:encoding(utf-8)', $file) or die "Couldn't open $file $!";
    # TODO add support for uid and cat (ATR)
    foreach my $directive (qw/title subtitle author LISTtitle SORTauthors
                              SORTtopics date uid cat
                              source lang pubdate/) {

        $self->_add_directive($fh, $directive, $params->{$directive});
    }
    # add the notes
    $self->_add_directive($fh, notes => html_to_muse($params->{notes}));

    # separator
    print $fh "\n";

    my $body = html_to_muse($params->{textbody});
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

=head2 new_revision_from_uri($uri)

Return a new revision object for the text uri or undef if it doesn't
exist.

=cut

sub new_revision_from_uri {
    my ($self, $uri) = @_;
    my $text = $self->titles->find({ uri => $uri });
    $text ? return $text->new_revision : return;
}

=head2 xapian

Return a L<AmuseWikiFarm::Archive::Xapian> object

=cut

sub xapian {
    my $self = shift;
    return AmuseWikiFarm::Archive::Xapian->new(
                                               code => $self->id,
                                               locale => $self->locale,
                                              );
}

=head2 collation_index

Update the C<sorting_pos> field of each text and category based on the
collation for the current locale.

Collation on the fly would have been too slow, or would depend on the
(possibly crappy) collation of the database engine, if any.

=cut

sub collation_index {
    my $self = shift;
    my $collator = Unicode::Collate::Locale->new(locale => $self->locale);

    my @texts = sort {
        # warn $a->id . ' <=>  ' . $b->id;
        $collator->cmp($a->list_title, $b->list_title)
    } $self->titles;

    my $i = 1;
    foreach my $t (@texts) {
        $t->sorting_pos($i++);
        $t->update if $t->is_changed;
    }

    # and then sort the categories
    my @categories = sort {
        # warn $a->id . ' <=> ' . $b->id;
        $collator->cmp($a->name, $b->name)
    } $self->categories;

    $i = 1;
    foreach my $cat (@categories) {
        $cat->sorting_pos($i++);
        $cat->update if $cat->is_changed;
    }

}

=head2 index_file($path_to_file)

Add the file to the DB and Xapian databases, first parsing it with
C<muse_info_file> from L<AmuseWikiFarm::Utils::Amuse>.

=cut

sub index_file {
    my ($self, $file) = @_;
    unless ($file && -f $file) {
        $file ||= '<empty>';
        warn "File $file does not exist";
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
        warn "Inserting data for attachment $file\n";
        $self->attachments->update_or_create($details);
        return $file;
    }

    # handle specials and texts

    # ready to store into titles?
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

    # this is needed because we insert it from title, and DBIC can't
    # infer the site_id from there (even if it should, but hey).
    my @parsed_cats;
    if (my $cats_from_title = delete $details->{parsed_categories}) {
        foreach my $cat (@$cats_from_title) {
            $cat->{site_id} = $self->id;
            push @parsed_cats, $cat;
        }
    }
    if (%$details) {
        warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
    }
    print "Inserting data for $file\n";
    # TODO: see if we have to update the insertion

    my $title = $self->titles->update_or_create(\%insertion)->get_from_storage;

    # pick the old categories.
    my @old_cats_ids;
    foreach my $old_cat ($title->categories) {
        push @old_cats_ids, $old_cat->id;
    }

    if ($title->is_deleted) {
        $title->status('deleted');
    }
    elsif ($title->is_deferred) {
        $title->status('deferred');
    }
    elsif ($title->is_published) {
        $title->status('published');
    }
    $title->update if $title->is_changed;

    if ($title->is_published && @parsed_cats) {
        # here we can die if there are duplicated uris
        $title->set_categories(\@parsed_cats);
    }
    else {
        # purge the categories if there is none.
        $title->set_categories([]);
    }

    foreach my $cat ($title->categories) {
        $cat->title_count_update;
    }

    foreach my $cat_id (@old_cats_ids) {
        my $cat = $self->categories->find($cat_id);
        $cat->title_count_update;
    }

    # XAPIAN INDEXING
    $self->xapian->index_text($title);
    return $file;
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

=head3 update_db_from_tree

Check the consistency of the repo and the db. Index and compile
new/changed files and purge the removed ones.

TODO: logging

=cut

sub update_db_from_tree {
    my ($self, $logger) = @_;
    my $todo = $self->repo_find_changed_files;

    # first delete
    foreach my $purge (@{ $todo->{removed} }) {
        if (my $found = $self->find_file_by_path($purge)) {
            $found->delete;
        }
        else {
            warn "$purge was not present in the db!";
        }
    }
    my $compiler = Text::Amuse::Compile->new($self->compile_options);
    if ($logger) {
        $compiler->logger($logger);
    }
    foreach my $new (sort @{ $todo->{new} }, @{ $todo->{changed} }) {
        my $file = File::Spec->catfile($self->repo_root, $new);
        print "Indexing $file\n";
        $self->index_file($file);

        # skip already compiled files or not muse files
        next unless $file =~ m/\.muse$/;
        next unless $compiler->file_needs_compilation($file);

        my $failure = 0;
        $compiler->report_failure_sub(sub {  $failure = 1 });
        $compiler->compile($file);
        if ($failure) {
            my $failed = $self->titles->find({ f_full_path_name => $file });
            if ($failed) {
                $failed->status('deleted');
                $failed->deleted(q{Document has errors and couldn't be compiled});
            }
            else {
                warn "Couldn't find $file in the db\n";
            }
        }
    }
    $self->collation_index;
}


=head2 find_file_by_path($path)

Return a title or attachment depending on the path provided (or
nothing if not found).

=cut

sub find_file_by_path {
    my ($self, $path) = @_;
    return unless $path;
    my ($name, $dirs, $suffix) = fileparse($path, '.muse');
    # TODO add support for the special pages when dumped in the git
    if ($suffix eq '.muse') {
        my $title = $self->titles->find({ uri => $name });
        return $title;
    }
    else {
        my $file = $self->attachments->find({ uri => $name });
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

Return a list of remote gits found in the repo.

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

=head2 remote_git

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

sub related_sites {
    my $self = shift;
    my @related = $self->other_sites->search({},
                                             { columns => [qw/canonical
                                                              sitename/] });
    my @out;
    foreach my $r (@related) {
        push @out, { uri => $r->canonical,
                     current => ($r->canonical eq $self->canonical),
                     name => ($r->sitename || $r->canonical) };
    }
    return @out;
}

sub special_list {
    my $self = shift;
    my @list = $self->titles->published_specials
      ->search({},
               { columns => [qw/title uri/] });
    my @out;
    foreach my $l (@list) {
        push @out, {
                    uri => $l->uri,
                    name => $l->title || $l->uri
                   };
    }
    return @out;
}


__PACKAGE__->meta->make_immutable;

1;
