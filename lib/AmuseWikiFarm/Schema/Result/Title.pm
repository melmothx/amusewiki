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
  is_nullable: 1
  size: 255

=head2 attach

  data_type: 'varchar'
  is_nullable: 1
  size: 255

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
  size: 4

=head2 f_timestamp

  data_type: 'datetime'
  is_nullable: 0

=head2 f_full_path_name

  data_type: 'text'
  is_nullable: 0

=head2 f_suffix

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

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 8

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
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "attach",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "f_timestamp",
  { data_type => "datetime", is_nullable => 0 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 0 },
  "f_suffix",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "deleted",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 8 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-26 08:30:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uhXbrjXhNVH0o/Cd9Wbu5Q

use File::Spec;
use File::Slurp qw/read_file/;
use DateTime;

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
current datetime.

=head3 is_published

B<Check> if it's not deleted and if it's not deferred. 

=head3 is_deleted

Return true if is deleted, false otherwise.

=head3 is_deferrend

Return true if the publish date is set in the future.

=cut

sub is_published {
    my $self = shift;
    if ($self->is_deleted || $self->is_deferred) {
        return 0;
    }
    else {
        return 1;
    }
}

sub is_deleted {
    my $self = shift;
    $self->deleted eq '' ? return 0 : return 1;
}

sub is_deferred {
    my $self = shift;
    $self->pubdate->epoch > DateTime->now->epoch ? return 1 : return 0;
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
    my $text = read_file($file => { binmode => ':encoding(UTF-8)' });
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

__PACKAGE__->meta->make_immutable;
1;
