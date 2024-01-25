use utf8;
package AmuseWikiFarm::Schema::Result::WhitelistIp;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::WhitelistIp - IP whitelisting for access to private sites

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

=head1 TABLE: C<whitelist_ip>

=cut

__PACKAGE__->table("whitelist_ip");

=head1 ACCESSORS

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 ip

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 user_editable

  data_type: 'smallint'
  default_value: 0
  is_nullable: 0

=head2 granted_by_username

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 expire_epoch

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "ip",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "user_editable",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "granted_by_username",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "expire_epoch",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</site_id>

=item * L</ip>

=back

=cut

__PACKAGE__->set_primary_key("site_id", "ip");

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


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-24 14:16:07
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jJ83qt+g37irvy0IkuvuDQ


use AmuseWikiFarm::Log::Contextual;

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index(name => 'whitelist_ip_ip_amw_index', fields => ['ip']);
}

__PACKAGE__->meta->make_immutable;
1;
