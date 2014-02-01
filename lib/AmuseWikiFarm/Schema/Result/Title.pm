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
  is_nullable: 1

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
  is_nullable: 1

=head2 author

  data_type: 'text'
  is_nullable: 1

=head2 uid

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 attach

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pubdate

  data_type: 'timestamp'
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
  size: 4

=head2 f_timestamp

  data_type: 'varchar'
  is_nullable: 0
  size: 255

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

=head2 site_id

  data_type: 'varchar'
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
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "source",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "list_title",
  { data_type => "text", is_nullable => 1 },
  "author",
  { data_type => "text", is_nullable => 1 },
  "uid",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "attach",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pubdate",
  { data_type => "timestamp", is_nullable => 1 },
  "f_path",
  { data_type => "text", is_nullable => 0 },
  "f_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_archive_rel_path",
  { data_type => "varchar", is_nullable => 0, size => 4 },
  "f_timestamp",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 0 },
  "f_suffix",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "deleted",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_nullable => 0, size => 16 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-01-31 12:27:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7XIM6UcQLUx/ISpVxSLlrA

use File::Spec;
use File::Slurp qw/read_file/;

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

=cut

sub topic_list {
    return shift->category_listing(topic => ', ');
}

sub author_list {
    return shift->category_listing(author => ', ');
}

sub category_listing {
    my ($self, $type, $sep) = @_;
    my @cats;
    foreach my $cat ($self->categories->search({ type => $type })) {
        push @cats, $cat->name;
    }
    @cats ? return join($sep, @cats) : return '';
}

=head2 File serving

=head3 filepath_for_ext($ext)

Given the extension (without the leading dot) as argument, return the
filename. It's not guaranteed to exists, though.

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

=cut

sub html_body {
    my $self = shift;
    my $barefile = File::Spec->catfile($self->f_path,
                               $self->f_name . '.bare.html');
    return "No body found!" unless -f $barefile;
    my $text = read_file($barefile => { binmode => ':encoding(UTF-8)' });
    return $text;
}

__PACKAGE__->meta->make_immutable;
1;
