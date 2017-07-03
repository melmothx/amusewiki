use utf8;
package AmuseWikiFarm::Schema::Result::Backlink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Backlink

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

=head1 TABLE: C<backlink>

=cut

__PACKAGE__->table("backlink");

=head1 ACCESSORS

=head2 title_linked_to

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title_linked_from

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "title_linked_to",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title_linked_from",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</title_linked_to>

=item * L</title_linked_from>

=back

=cut

__PACKAGE__->set_primary_key("title_linked_to", "title_linked_from");

=head1 RELATIONS

=head2 title_linked_from

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title_linked_from",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_linked_from" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 title_linked_to

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title_linked_to",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_linked_to" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-07-03 12:04:37
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IiEEiRojbw2LbTUqPxX85g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
