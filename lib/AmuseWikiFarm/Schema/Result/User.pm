use utf8;
package AmuseWikiFarm::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::User

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


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2015-10-27 10:30:45
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mdxcXvPcBaQ/f6aAio814w


# Have the 'password' column use a SHA-1 hash and 20-byte salt
# with RFC 2307 encoding; Generate the 'check_password" method
__PACKAGE__->add_columns(
    'password' => {
        data_type => "varchar",
        is_nullable => 0,
        size => 255,
        passphrase       => 'rfc2307',
        passphrase_class => 'SaltedDigest',
        passphrase_args  => {
            algorithm   => 'SHA-1',
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    },
);

sub available_roles {
    return qw/librarian root/;
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


__PACKAGE__->meta->make_immutable;

1;
