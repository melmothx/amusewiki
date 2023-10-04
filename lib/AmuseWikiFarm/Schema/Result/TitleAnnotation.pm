use utf8;
package AmuseWikiFarm::Schema::Result::TitleAnnotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::TitleAnnotation

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

=head1 TABLE: C<title_annotation>

=cut

__PACKAGE__->table("title_annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 annotation_value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "annotation_value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</annotation_id>

=item * L</title_id>

=back

=cut

__PACKAGE__->set_primary_key("annotation_id", "title_id");

=head1 RELATIONS

=head2 annotation

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Annotation>

=cut

__PACKAGE__->belongs_to(
  "annotation",
  "AmuseWikiFarm::Schema::Result::Annotation",
  { annotation_id => "annotation_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 title

Type: belongs_to

Related object: L<AmuseWikiFarm::Schema::Result::Title>

=cut

__PACKAGE__->belongs_to(
  "title",
  "AmuseWikiFarm::Schema::Result::Title",
  { id => "title_id" },
  { is_deferrable => 0, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2023-10-01 08:37:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZK2MrOhm7Wq1pasOD8hBgA
use Path::Tiny ();
use Try::Tiny;
use AmuseWikiFarm::Log::Contextual;

sub valid_value {
    my ($self) = @_;
    my $annotation = $self->annotation;
    my $value = $self->annotation_value;
    if ($value and $annotation->annotation_type eq 'file') {
        $value = undef;
        if (my $file = $self->validate_file) {
            log_debug { "Value is $file" };
            $value = join("/",
                          "/annotation/download",
                          $self->title->id,
                          $annotation->annotation_id,
                          $file->basename);
        }
    }
    return $value;
}

sub validate_file {
    my ($self) = @_;
    my $annotation = $self->annotation;
    my $value = $self->annotation_value;
    if ($value and $annotation->annotation_type eq 'file') {
        my $raw = $value;
        log_debug { "File is $raw (not validated)" };
        $value = undef;
        try {
            my $repo_root = Path::Tiny::path($annotation->site->repo_root)->realpath;
            my $file = Path::Tiny::path($repo_root, $raw)->realpath;
            if ($file->exists) {
                # realpaths already resolved above
                if ($repo_root->subsumes($file)) {
                    log_debug { "OK, returning $file" };
                    $value = $file;
                }
                else {
                    log_warn { "$file not under $repo_root" };
                }
            }
            else {
                log_warn { "$file does not exists in $repo_root" };
            }
        }
        catch {
            my $err = $_;
            log_warn { "Error in handling file $raw annotation $err" };
        };
        return $value;
    }
    return;
}




__PACKAGE__->meta->make_immutable;
1;
