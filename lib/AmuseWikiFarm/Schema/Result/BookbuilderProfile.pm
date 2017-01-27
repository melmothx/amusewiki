use utf8;
package AmuseWikiFarm::Schema::Result::BookbuilderProfile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::BookbuilderProfile - Bookbuilder profiles

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

=head1 TABLE: C<bookbuilder_profile>

=cut

__PACKAGE__->table("bookbuilder_profile");

=head1 ACCESSORS

=head2 bookbuilder_profile_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 profile_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 custom_formats_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 profile_data

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "bookbuilder_profile_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "profile_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "custom_formats_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "profile_data",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</bookbuilder_profile_id>

=back

=cut

__PACKAGE__->set_primary_key("bookbuilder_profile_id");

=head1 RELATIONS

=head2 custom_format

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::CustomFormat>

=cut

__PACKAGE__->belongs_to(
  "custom_format",
  "AmuseWikiFarm::Schema::Result::CustomFormat",
  { custom_formats_id => "custom_formats_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

=head2 user

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "AmuseWikiFarm::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-01-27 14:52:15
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iJwXZID4O4Uhk9sIwth4gw

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse ();

sub bookbuilder_arguments {
    my $self = shift;
    my $json = $self->profile_data;
    my $data = AmuseWikiFarm::Utils::Amuse::from_json($json);
    if ($data) {
        return $data;
    }
    else {
        log_error { "Cannot load profile $json for id " . $self->bookbuilder_profile_id };
        return {};
    };
}

sub update_profile_from_bb {
    my ($self, $bb) = @_;
    my $data = $bb->serialize_profile;
    $self->update({ profile_data => AmuseWikiFarm::Utils::Amuse::to_json($data) });
}

sub rename_profile {
    my ($self, $name) = @_;
    if (defined($name)) {
        $self->update({ profile_name => $name . ''});
    }
}


__PACKAGE__->meta->make_immutable;
1;
