use utf8;
package AmuseWikiFarm::Schema::Result::Job;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Job

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

=head1 TABLE: C<job>

=cut

__PACKAGE__->table("job");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 8

=head2 task

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 payload

  data_type: 'text'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 created

  data_type: 'datetime'
  is_nullable: 0

=head2 completed

  data_type: 'datetime'
  is_nullable: 0

=head2 priority

  data_type: 'integer'
  is_nullable: 1

=head2 errors

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 8 },
  "task",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "payload",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "completed",
  { data_type => "datetime", is_nullable => 0 },
  "priority",
  { data_type => "integer", is_nullable => 1 },
  "errors",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-15 23:40:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+KRT8PQvOnE9Tjn+9t199w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
