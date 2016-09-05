use utf8;
package AmuseWikiFarm::Schema::Result::BookbuilderSession;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::BookbuilderSession - Bookbuilder sessions

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

=head1 TABLE: C<bookbuilder_session>

=cut

__PACKAGE__->table("bookbuilder_session");

=head1 ACCESSORS

=head2 bookbuilder_session_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 token

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 bb_data

  data_type: 'text'
  default_value: '{}'
  is_nullable: 0

=head2 last_updated

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bookbuilder_session_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "token",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "bb_data",
  { data_type => "text", default_value => "{}", is_nullable => 0 },
  "last_updated",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bookbuilder_session_id>

=back

=cut

__PACKAGE__->set_primary_key("bookbuilder_session_id");

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-09-05 13:29:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z55B0A6xBWXktneH7OctLw

sub full_token {
    my $self = shift;
    return $self->token . '-' . $self->bookbuilder_session_id;
}

__PACKAGE__->meta->make_immutable;
1;
