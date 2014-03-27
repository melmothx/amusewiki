use utf8;
package AmuseWikiFarm::Schema::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Page

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

=head1 TABLE: C<page>

=cut

__PACKAGE__->table("page");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 8

=head2 pubdate

  data_type: 'datetime'
  is_nullable: 0

=head2 created

  data_type: 'datetime'
  is_nullable: 0

=head2 updated

  data_type: 'datetime'
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 uri

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 html_body

  data_type: 'text'
  is_nullable: 1

=head2 f_path

  data_type: 'text'
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  default_value: 'published'
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 8 },
  "pubdate",
  { data_type => "datetime", is_nullable => 0 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "updated",
  { data_type => "datetime", is_nullable => 0 },
  "user_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "uri",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "html_body",
  { data_type => "text", is_nullable => 1 },
  "f_path",
  { data_type => "text", is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "published",
    is_nullable => 0,
    size => 16,
  },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-27 13:43:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zKo0up91CuT93tMXnTbXFA

use File::Slurp;

sub muse_body {
    my $self = shift;
    my $filepath = $self->f_path;
    unless (-f $filepath and $filepath =~ m/\.muse$/) {
        warn "$filepath is not there!";
        return;
    }
    my $text = read_file($self->f_path => { binmode => ':encoding(UTF-8)' });
    return $text;
}


__PACKAGE__->meta->make_immutable;
1;
