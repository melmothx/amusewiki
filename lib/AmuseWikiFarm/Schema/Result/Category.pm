use utf8;
package AmuseWikiFarm::Schema::Result::Category;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Category

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
  size: 8

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
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 8 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-11 08:12:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UOOouoTsn4olsp4DxR3sqQ


=head2 title_count_update

Update the published texts count. It doesn't look at the text_count in
the row, but rather B<set> it.

=cut

sub title_count_update {
    my $self = shift;
    my $count = $self->titles->published_texts->count;
    $self->text_count($count);
    $self->update if $self->is_changed;
}

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
    if ($type eq 'topic') {
        return "/topics/$uri";
    }
    elsif ($type eq 'author') {
        return "/authors/$uri";
    }
    elsif ($type eq 'category') {
        return "/category/$uri";
    }
    else {
        die "WTF?";
    }
}

__PACKAGE__->meta->make_immutable;
1;
