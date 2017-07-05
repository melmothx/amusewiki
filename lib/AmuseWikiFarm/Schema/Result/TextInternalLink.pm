use utf8;
package AmuseWikiFarm::Schema::Result::TextInternalLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::TextInternalLink - Internal links found in the body

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

=head1 TABLE: C<text_internal_link>

=cut

__PACKAGE__->table("text_internal_link");

=head1 ACCESSORS

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 url_host

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 f_class

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 uri

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "url_host",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "f_class",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "uri",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);

=head1 RELATIONS

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-07-05 11:46:24
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jIziiME+0EjprgfgNZZ/Qg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
