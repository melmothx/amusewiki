use utf8;
package AmuseWikiFarm::Schema::Result::JobFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::JobFile - Files produced by a job

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-02-17 19:36:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i1x91Jw3v2piwMa/RMnaLQ

use File::Spec;
use AmuseWikiFarm::Archive::BookBuilder;

=head1 METHODS

=head2 basedir

Calls C<filedir> on L<AmuseWikiFarm::Archive::BookBuilder> and return
the absolute path.

=head2 path

Use C<basedir> to provide the absolute path for C<filename>.

=cut

sub basedir {
    return File::Spec->rel2abs(AmuseWikiFarm::Archive::BookBuilder->filedir);
}

sub path {
    my $self = shift;
    return File::Spec->catfile($self->basedir, $self->filename);
}

__PACKAGE__->meta->make_immutable;
1;
