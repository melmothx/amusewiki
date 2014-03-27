use utf8;
package AmuseWikiFarm::Schema::Result::Revision;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Revision

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

=head1 TABLE: C<revision>

=cut

__PACKAGE__->table("revision");

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

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 f_full_path_name

  data_type: 'text'
  is_nullable: 1

=head2 updated

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 8 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "f_full_path_name",
  { data_type => "text", is_nullable => 1 },
  "updated",
  { data_type => "datetime", is_nullable => 0 },
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

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-26 12:38:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+kcdIGDZPSeRauslB6tq6A

use File::Slurp;
use File::Basename qw/fileparse/;
use File::Spec;
use Text::Amuse;
use File::Copy qw/copy move/;


=head2 muse_body

Return the text stored in the staging area (for editing)

=head2 muse_doc

Return a L<Text::Amuse> object for that file.

=cut

sub muse_body  {
    my $self = shift;
    my $file = $self->f_full_path_name;
    return '' unless -f $file;
    my $body = read_file($file => { binmode => ':encoding(utf-8)' });
    return $body;
}

sub muse_doc {
    my $self = shift;
    my $file = $self->f_full_path_name;
    return '' unless -f $file;
    my $doc = Text::Amuse->new(file => $file);
    return $doc;
}

sub file_parsing {
    my ($self, $type) = @_;
    my ($name, $path, $suffix) = fileparse($self->f_full_path_name, '.muse');
    if ($type eq 'dir') {
        return $path;
    }
    elsif ($type eq 'name') {
        return $name;
    }
}

sub muse_uri {
    return shift->file_parsing('name');
}

sub working_dir {
    return shift->file_parsing('dir');
}

=head2 private files

They have an underscore, so they are invalid files for use and avoid clashes.

=cut

sub starting_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_orig.muse');
}

sub original_html {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_orig.html');
}

sub temporary_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_tmp.muse');
}

sub aux_file {
    my $self = shift;
    return File::Spec->catfile($self->working_dir, 'private_aux.muse');
}

=head2 attached_files

Return an array reference to the list of attached basenames.

=cut

sub attached_files {
    my $self = shift;
    my @files;
    my $dir = $self->working_dir;
    opendir(my $dh, $dir) || die "can't opendir $dir: $!";
    # we know only about pdf, jpeg, png
    @files = grep { /\w\.(pdf|jpe?g|png)$/ && -f File::Spec->catfile($dir, $_) }
      readdir($dh);
    closedir $dh;
    return \@files;
}

sub attached_file_path {
    my ($self, $name) = @_;
    return unless $name;
    my $path = File::Spec->catfile($self->working_dir, $name);
    return unless -f $path;
    return $path;
}

=head2 attached_files_path

Return a list of absolute path to the attached files.

=cut


sub attached_files_paths {
    my $self = shift;
    my @paths;
    foreach my $file (@{$self->attached_files}) {
        my $path = $self->attached_file_path($file);
        push @paths, $path if $path;
    }
    return @paths;
}


=head2 edit(\$string)

Edit the current revision. It's reccomended to pass a reference to a
scalar or an hashref with the string in the "body" key to avoid large
copying, but a scalar will do the same.

=cut

sub edit {
    my ($self, $string) = @_;
    die "Missing argument" unless $string;

    my $target   = $self->f_full_path_name;
    my $original = $self->starting_file;
    my $temp     = $self->temporary_file;
    my $aux      = $self->aux_file;
    # check if we have the main file
    die "Can't edit a non-existent file!" unless -f $target;

    # assert that we have the starting point file
    unless (-f $original) {
        copy($target, $original) or die "Couldn't copy $target to $original $!";
    }

    my $is_ref = ref($string);

    # before overwriting, we do some mambo-jumbo to strip out \r

    # save the parameter in the temporary file
    open (my $fh, '>:encoding(utf-8)', $temp) or die "Fail to open $temp $!";
    if ($is_ref eq 'SCALAR') {
        print $fh $$string;
    }
    elsif ($is_ref eq 'HASH' and exists $string->{body}) {
        print $fh $string->{body};
    }
    elsif (!$is_ref) {
        print $fh $string;
    }
    else {
        die "Failed to write string, bad usage!";
    }
    close $fh or die "Fail to close $temp $!";

    # then filter it and write to an aux
    open (my $tmpfh, '<:encoding(utf-8)', $temp) or die "Can't open $temp $!";
    open (my $auxfh, '>:encoding(utf-8)', $aux) or die "Can't open $aux $!";

    # TODO this is the good place to use the filters, not modifying the params
    while (<$tmpfh>) {
        s/\r//;
        s/\t/    /;
        print $auxfh $_;
    }
    close $auxfh or die $!;
    close $tmpfh or die $!;
    move($aux, $target) or die "Couldn't move $aux to $target";
    # finally move it to the target file
}

=head2 add_attachment($filename)

Given the filename as first argument, copy it into the working
directory, taking care of not overwrite anything. Return 0 on success,
the error otherwise.

=cut

sub add_attachment {
    my ($self, $filename) = @_;
    die "Missing argument" unless $filename;
    return "$filename doesn't exist" unless -f $filename;
    return "Couldn't upload $filename!: not implemented";
}


__PACKAGE__->meta->make_immutable;
1;
