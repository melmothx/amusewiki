use utf8;
package AmuseWikiFarm::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Category - Text categories

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

=head1 TABLE: C<category>

=cut

__PACKAGE__->table("category");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 sorting_pos

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 text_count

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
  "name",
  { data_type => "text", is_nullable => 1 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "sorting_pos",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "text_count",
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

=head2 C<uri_site_id_type_unique>

=over 4

=item * L</uri>

=item * L</site_id>

=item * L</type>

=back

=cut

__PACKAGE__->add_unique_constraint("uri_site_id_type_unique", ["uri", "site_id", "type"]);

=head1 RELATIONS

=head2 category_descriptions

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::CategoryDescription>

=cut

__PACKAGE__->has_many(
  "category_descriptions",
  "AmuseWikiFarm::Schema::Result::CategoryDescription",
  { "foreign.category_id" => "self.id" },
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
  { "foreign.category_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 titles

Type: many_to_many

Composing rels: L</title_categories> -> title

=cut

__PACKAGE__->many_to_many("titles", "title_categories", "title");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C29cQenHAkgsAx2y9wSN1A

=head2 published_titles

Return a Title resultset, but only with published texts

=cut

sub published_titles {
    my $self = shift;
    my @titles = $self->titles->published_texts;
    return @titles;
}

sub full_uri {
    my $self = shift;
    my $type = $self->type;
    my $uri  = $self->uri;
    return '/' . join('/', 'category', $self->type, $self->uri);
}

sub localized_desc {
    my ($self, $lang) = @_;
    if ($lang) {
        return $self->category_descriptions->find({ lang => $lang });
    }
    return;
}

=head2 sorted_titles

Return a sorted list of published texts.

To be used when prefetching the titles, when the query already was
executed.


=cut

sub sorted_titles {
    my $self = shift;
    return sort { $a->sorting_pos <=> $b->sorting_pos }
      grep { $_->status eq 'published' } $self->titles->all;
}

sub cloud_level {
    my $self = shift;
    my $level = int($self->text_count / 5);
    if ($level > 20) {
        return 20;
    }
    else {
        return $level;
    }
}


=head2 sorting_fragments

Return an arrayref with 3 elements, a string, a number, a string. The
categories are supposed to be sorted with:

 $a->sorting_fragments->[0] cmp $b->sorting_fragments->[0] or
 $a->sorting_fragments->[1] <=> $b->sorting_fragments->[1] or
 $a->sorting_fragments->[2] cmp $b->sorting_fragments->[2]

Or equivalent.

The second element is supposed to be an issue number, so the sorting
would be correct (numeric sorting). E.g.:

 'Magazine #3 (Spring)' =>  ['Magazine #', 3, '(Summer)']

 'Magazine #23 (Summer)' =>  ['Magazine #', 23, '(Summer)']

 'Magazine #100' =>  ['Magazine #', 100, '']

 'Whatever' =>  ['Whatever', 0, '']

=cut


has sorting_fragments => (is => 'ro',
                          isa => 'ArrayRef',
                          lazy => 1,
                          builder => '_build_sorting_fragments',
                         );

sub _build_sorting_fragments {
    my $self = shift;
    my @out;
    my $name = $self->name;
    if ($name and $name =~ m/\A(.+?\#)([0-9]+)(.*)\z/) {
        my ($prefix, $number, $postfix) = ($1, $2, $3);
        $number =~ s/^0+//;
        $number ||= 0;
        $postfix //= '';
        $postfix =~ s/\A\s+//;
        @out = ($prefix, $number, $postfix);
    }
    else {
        @out = ($name, 0, '');
    }
    return \@out;
}



__PACKAGE__->meta->make_immutable;
1;
