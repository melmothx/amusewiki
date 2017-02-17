use utf8;
package AmuseWikiFarm::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::User - User definitions

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

=head1 TABLE: C<users>

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 created_by

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 edit_option_preview_box_height

  data_type: 'integer'
  default_value: 500
  is_nullable: 0

=head2 edit_option_show_filters

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 edit_option_show_cheatsheet

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 edit_option_page_left_bs_columns

  data_type: 'integer'
  default_value: 6
  is_nullable: 1

=head2 reset_token

  data_type: 'text'
  is_nullable: 1

=head2 reset_until

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "created_by",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "edit_option_preview_box_height",
  { data_type => "integer", default_value => 500, is_nullable => 0 },
  "edit_option_show_filters",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "edit_option_show_cheatsheet",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "edit_option_page_left_bs_columns",
  { data_type => "integer", default_value => 6, is_nullable => 1 },
  "reset_token",
  { data_type => "text", is_nullable => 1 },
  "reset_until",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username_unique>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

=head1 RELATIONS

=head2 bookbuilder_profiles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::BookbuilderProfile>

=cut

__PACKAGE__->has_many(
  "bookbuilder_profiles",
  "AmuseWikiFarm::Schema::Result::BookbuilderProfile",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "AmuseWikiFarm::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_sites

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::UserSite>

=cut

__PACKAGE__->has_many(
  "user_sites",
  "AmuseWikiFarm::Schema::Result::UserSite",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");

=head2 sites

Type: many_to_many

Composing rels: L</user_sites> -> site

=cut

__PACKAGE__->many_to_many("sites", "user_sites", "site");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r6spqVC6QBIIWHEpJHPqGg

__PACKAGE__->load_components(qw(PassphraseColumn));

# Have the 'password' column use a SHA-1 hash and 20-byte salt
# with RFC 2307 encoding; Generate the 'check_password" method
__PACKAGE__->add_columns(
    '+password' => {
        passphrase       => 'rfc2307',
        passphrase_class => 'SaltedDigest',
        passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    },
);

use AmuseWikiFarm::Log::Contextual;
use AmuseWikiFarm::Utils::Amuse ();

=head2 available_roles

Return C<librarian> and C<root>

=head2 available_sites

Return a list of hashrefs, where each of them has 3 keys, C<id> with
the site id, C<sitename> and C<canonical>.

=head2 role_list

Return an arrayref of hashrefs, where each of them has 2 keys, C<role>
with the role name, and active set to true if the user has that role.

=head2 site_list

Same result as C<available_sites>, but as an arrayref and with an
additional key C<active> set to true when the user belongs to the
site.

=cut

sub available_roles {
    return qw/librarian admin root/;
}

sub role_list {
    my $self = shift;
    my %roles = map { $_->role => 1 } $self->roles;
    my @out;
    foreach my $role ($self->available_roles) {
        push @out, { role => $role,
                     active => $roles{$role} };
    }
    return \@out;
}

sub available_sites {
    my $self = shift;
    my $sites = $self->result_source->schema->resultset('Site')
      ->search({}, {
                    columns => [qw/id sitename canonical/],
                    order_by => [qw/canonical/],
                   });
    my @out;
    while (my $site = $sites->next) {
        push @out, {
                    id => $site->id,
                    sitename => $site->sitename || $site->id,
                    canonical => $site->canonical,
                   };
    }
    return @out;

}

sub site_list {
    my $self = shift;
    my %sites = map { $_->id => 1 } $self->sites;
    my @out = $self->available_sites;
    foreach my $site (@out) {
        if ($sites{$site->{id}}) {
            $site->{active} = 1;
        }
    }
    return \@out;
}

=head2 set_password_hash($hash)

Set the raw value of the password field bypassing the hashing. If you
store random data here you will end up with broken users, so it's only
useful when migrating records across instances.

=cut

sub set_password_hash {
    my ($self, $value) = @_;
    die "Missing value" unless $value;
    $self->store_column(password => $value);
    $self->make_column_dirty('password');
    $self->update;
}

=head2 add_bb_profile($name, $bb)

Call serialize_profile on the second argument and save it in the
database with the first argument as name and return the new profile.

=cut

sub add_bb_profile {
    my ($self, $name, $bb) = @_;
    my $json = AmuseWikiFarm::Utils::Amuse::to_json($bb->serialize_profile);
    return $self->add_to_bookbuilder_profiles({
                                               profile_name => ($name || 'No name') . '',
                                               profile_data => $json,
                                              });
}

sub update_bb_profile {
    my ($self, $id, $bb) = @_;
    if (my $profile = $self->bookbuilder_profiles->find($id)) {
        my $data = $bb->serialize_profile;
        $profile->update({ profile_data => $data });
        return $profile;
    }
    return;
}

__PACKAGE__->meta->make_immutable;

1;
