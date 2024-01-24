use utf8;
package AmuseWikiFarm::Schema::Result::Annotation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

AmuseWikiFarm::Schema::Result::Annotation

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

=head1 TABLE: C<annotation>

=cut

__PACKAGE__->table("annotation");

=head1 ACCESSORS

=head2 annotation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 site_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 annotation_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 annotation_type

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 priority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0
  size: 1

=head2 private

  data_type: 'integer'
  default_value: 0
  is_nullable: 0
  size: 1

=cut

__PACKAGE__->add_columns(
  "annotation_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "site_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "annotation_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "annotation_type",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "priority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0, size => 1 },
  "private",
  { data_type => "integer", default_value => 0, is_nullable => 0, size => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</annotation_id>

=back

=cut

__PACKAGE__->set_primary_key("annotation_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<site_id_annotation_name_unique>

=over 4

=item * L</site_id>

=item * L</annotation_name>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "site_id_annotation_name_unique",
  ["site_id", "annotation_name"],
);

=head1 RELATIONS

=head2 aggregation_annotations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::AggregationAnnotation>

=cut

__PACKAGE__->has_many(
  "aggregation_annotations",
  "AmuseWikiFarm::Schema::Result::AggregationAnnotation",
  { "foreign.annotation_id" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

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

=head2 title_annotations

Type: has_many

Related object: L<AmuseWikiFarm::Schema::Result::TitleAnnotation>

=cut

__PACKAGE__->has_many(
  "title_annotations",
  "AmuseWikiFarm::Schema::Result::TitleAnnotation",
  { "foreign.annotation_id" => "self.annotation_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07051 @ 2024-01-18 18:05:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h1en/hmsPCQDSpHegRVMiA

use Path::Tiny ();
use AmuseWikiFarm::Utils::Paths ();
use AmuseWikiFarm::Log::Contextual;
use File::MimeInfo::Magic qw/mimetype/;
use HTML::Entities ();
use Try::Tiny;

sub annotate {
    my ($self, $object, $update) = @_;
    # now, we can have both text and annotations, s
    my ($type, $store) = $self->_identify_object($object);
    my @errors;
    Dlog_debug { "Updating $type annotation $_" }  $update;
    my $site = $self->site;

    my @path = ($site->repo_root, $site->annotations_directory);
    # create directory and add gitingore
    my $gitignore = Path::Tiny::path(@path, '.gitignore');
    $gitignore->parent->mkpath;
    unless ($gitignore->exists) {
        $gitignore->spew_utf8("*\n*/\n");
    }

    # annotation name: sanity check
    if ($self->annotation_name =~ m/\A([a-z0-9][a-z0-9-]*[a-z0-9])\z/) {
        push @path, $1;
    }
    else {
        return { errors => [ "Bad annotation name " . $self->annotation_name ] };
    }

    push @path, $type;

    if ($object->can('f_archive_rel_path')) {
        if (my $relpath = $object->f_archive_rel_path) {
            push @path, grep { /\A[a-z0-9-]+\z/ } split(/\//, $relpath);
        }
    }
    if ($self->annotation_type eq 'file' and my $file = $update->{file}) {
        delete $update->{value};
        if (-f $file) {
            my $mime = mimetype($file);
            my $all_mime = AmuseWikiFarm::Utils::Paths::served_mime_types();
            my %mimes = reverse %$all_mime;
            if (my $ext = $mimes{$mime}) {
                my $storage = Path::Tiny::path(@path, $object->uri . ".$ext");
                $storage->parent->mkpath;
                if (Path::Tiny::path($file)->copy($storage)) {
                    log_debug { "File copied in $storage" };
                    $update->{value} = $storage->relative($path[0]);
                }
                else {
                    push @errors, "Could not copy $update->{file}";
                }
            }
            else {
                push @errors, "$update->{file} has invalid mime $mime";
            }
        }
        else {
            push @errors, "$update->{file} not found, cannot add to annotation";
        }
    }
    if (@errors) {
        return { errors => \@errors };
    }
    my $value = $update->{value};
    my $destination = Path::Tiny::path(@path, $object->uri);
    $destination->parent->mkpath;
    log_debug { "Saving update in $destination" };
    if ($update->{remove}) {
        log_info { "Removing $store" };
        $store->delete;
        $destination->remove if $destination->exists;
    }
    elsif (defined $value) {
        # save the content in a file, so we can reconstruct the tree.
        my $destination = Path::Tiny::path(@path, $object->uri);
        $destination->spew_utf8($value);
        $store->update({ annotation_value => $value });
    }
    else {
        push @errors, $self->annotation_name . " was not passed!";
    }
    return { errors => \@errors };
}

sub values_for_object {
    my ($self, $object, $uri_prefix) = @_;
    my %out = (
               label => $self->label,
               name => $self->annotation_name,
               id => $self->annotation_id,
               type => $self->annotation_type,
               private => $self->private,
               value => undef,
              );
    return \%out unless $object;
    my ($type, $store) = $self->_identify_object($object);
    my $value = $store->annotation_value;
    if ($value and $self->annotation_type eq 'file') {
        if (my $valid = $self->_validate_file($value)) {
            $out{file_path} = $valid;
            if ($uri_prefix) {
                $out{url} = join("/", $uri_prefix,
                                 qw/annotation download/,
                                 $self->annotation_id,
                                 $type,
                                 $object->uri,
                                 $valid->basename);
            }
        }
        else {
            $value = undef;
        }
    }
    $out{value} = $value;
    if (defined $value) {
        my $html = HTML::Entities::encode_entities($value, q{<>&"'});
        $html =~ s/\r?\n/<br>/g;
        $out{html} = $html;
    }
    return \%out;
}

sub _validate_file {
    my ($self, $raw) = @_;
    log_debug { "File is $raw (not validated)" };
    my $value;
    try {
        my $repo_root = Path::Tiny::path($self->site->repo_root)->realpath;
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


sub _identify_object {
    my ($self, $object) = @_;
    my ($type, $store);
    if ($object->isa('AmuseWikiFarm::Schema::Result::Title')) {
        $type = $object->f_class;
        $store = $self->title_annotations->find_or_create({ title => $object });
    }
    elsif ($object->isa('AmuseWikiFarm::Schema::Result::Aggregation')) {
        $type = 'aggregation';
        $store = $self->aggregation_annotations->find_or_create({ aggregation => $object });
        log_error { "$store" };
    }
    else {
        die "Invalid object passed";
    }
    return ($type, $store);
}

__PACKAGE__->meta->make_immutable;
1;
