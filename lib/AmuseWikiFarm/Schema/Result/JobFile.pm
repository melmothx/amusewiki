use utf8;
package AmuseWikiFarm::Schema::Result::JobFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::JobFile

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

=head1 TABLE: C<job_file>

=cut

__PACKAGE__->table("job_file");

=head1 ACCESSORS

=head2 filename

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 slot

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 job_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "filename",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "slot",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "job_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</filename>

=back

=cut

__PACKAGE__->set_primary_key("filename");

=head1 RELATIONS

=head2 job

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Job>

=cut

__PACKAGE__->belongs_to(
  "job",
  "AmuseWikiFarm::Schema::Result::Job",
  { id => "job_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07040 @ 2015-11-26 12:38:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Yv+XqL4yepoWNn/D2QSNQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
