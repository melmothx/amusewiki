use utf8;
package AmuseWikiFarm::Schema::Result::Generate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Generate

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

=head1 TABLE: C<generate>

=cut

__PACKAGE__->table("generate");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
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

=head2 ttdir

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 1024

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 8

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
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
  "ttdir",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 1024 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 8 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_unique>

=over 4

=item * L</site_id>

=back

=cut

__PACKAGE__->add_unique_constraint("site_id_unique", ["site_id"]);

=head1 RELATIONS

=head2 site

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Site>

=cut

__PACKAGE__->belongs_to(
  "site",
  "AmuseWikiFarm::Schema::Result::Site",
  { id => "site_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-01 20:29:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7FR2AP+4yiVIZGDjpKMT5A

=head2 compile_options

Hash with the formats to feed Text::Amuse::Compile (all the column,
minus C<id> and C<site_id>.

=cut

sub compile_options {
    my $self = shift;
    my %hash = $self->get_columns;
    delete $hash{id};
    delete $hash{ttdir} unless $hash{ttdir};
    delete $hash{site_id};
    return %hash;
}


__PACKAGE__->meta->make_immutable;
1;
