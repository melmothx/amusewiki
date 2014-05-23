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
  is_nullable: 0
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
  is_nullable: 1

=head2 priority

  data_type: 'integer'
  is_nullable: 1

=head2 produced

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 errors

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 8 },
  "task",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "payload",
  { data_type => "text", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "created",
  { data_type => "datetime", is_nullable => 0 },
  "completed",
  { data_type => "datetime", is_nullable => 1 },
  "priority",
  { data_type => "integer", is_nullable => 1 },
  "produced",
  { data_type => "varchar", is_nullable => 1, size => 255 },
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
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-27 13:43:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OtIcCassMd3LqfX1YQUvBg

use JSON qw/to_json
            from_json/;

use File::Spec;
use File::Slurp qw/read_file append_file/;
use Cwd;

=head2 as_json

Return the json string for the job

=cut

sub as_json {
    my $self = shift;
    my $struct = {
                  id       => $self->id,
                  site_id  => $self->site_id,
                  task     => $self->task,
                  payload  => from_json($self->payload),
                  status   => $self->status,
                  created  => $self->created->iso8601,
                  # completed => $self->completed->iso8601,
                  priority => $self->priority,
                  produced => $self->produced,
                  errors   => $self->errors,
                  logs     => $self->logs,
                 };
    return to_json($struct);
}

=head2 log_file

Return the location of the log file. Beware that the location is
computed in the current directory, but returned as absolute.

=cut

sub log_file {
    my $self = shift;
    my $dir = File::Spec->catdir(qw/log jobs/);
    die "We're in the wrong directory: " . getcwd()  unless -d $dir;
    my $file = File::Spec->catfile($dir, $self->id . '.log');
    return File::Spec->rel2abs($file);
}

=head2 logs

Return the content of the log file.

=cut

sub logs {
    my $self = shift;
    my $file = $self->log_file;
    if (-f $file) {
        my $log = read_file($file => { binmode => ':encoding(UTF-8)' });
        # obfuscate the current directory
        my $cwd = getcwd();
        $log =~ s/$cwd/./g;
        return $log;
    }
    return '';
}

=head2 logger

Return a sub for logging into C<log_file>

=cut

sub logger {
    my $self = shift;
    my $logfile = $self->log_file;
    my $logger = sub {
        append_file($logfile, { binmode => ':encoding(utf-8)' }, @_);
    };
    return $logger;
}

__PACKAGE__->meta->make_immutable;
1;
