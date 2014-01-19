package AmuseWikiFarm::Utils::Amuse;
use utf8;
use strict;
use warnings;

use Data::Dumper;
use File::Spec;
use File::Basename;
use Text::Amuse::Functions qw/muse_fast_scan_header/;
use HTML::Entities qw/decode_entities/;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw/muse_file_info/;

=head2 muse_file_info($file, $site_id)

Scan the header of the file $file and collect all the relevant
informations, returning them as a hashref. It includes also the file
attributes, like timestamp, paths, etc.

The result is suitable to feed the database, so see
L<AmuseWikiFarm::Schema::Result::Title> for the returned keys and the
AmuseWiki manual for the list of supported and defined directives.

Special cases:

LISTtitle in the header will map to C<list_title>, defaulting to
C<title>, where any leading non-word characters are stripped (which is
the meaning of the LISTtitle).

This function makes sense only in a full installation of AmuseWiki, so
if the files are not in the right path, the indexing is skipped.

=cut

sub muse_file_info {
    my ($file, $site_id) = @_;
    die "$file not found!" unless -f $file;
    $site_id ||= 'default';
    my $details = _parse_muse_file($file);
    return unless $details;

    # TODO
    my $authors = delete $details->{SORTauthors};
    unless (defined($authors)) {
        $authors = $details->{author};
    }

    # TODO
    delete $details->{SORTtopics};

    # TODO fixed categories, to lookup in tables, space separated
    delete $details->{cat};

    my $title_order_by = delete $details->{LISTtitle};
    if (defined $title_order_by and length($title_order_by)) {
        $details->{list_title} = $title_order_by;
    }
    else {
        $title_order_by = $details->{title};
        if (defined($title_order_by) and $title_order_by =~ m/\w/) {
            $title_order_by =~ s/^[\W]+//;
            $details->{list_title} = $title_order_by;
        }
    }

    # check if the title exists
    unless ($details->{title}) {
        warn "$file has no title! Setting deletion\n";
        $details->{deleted} ||= "Missing title";
    }

    $details->{site_id} = $site_id;
    $details->{uri} = $details->{f_name};
    return $details;
}

sub _parse_muse_file {
    my $file = shift;
    unless (File::Spec->file_name_is_absolute($file)) {
        $file = File::Spec->rel2abs($file);
    }
    my ($name, $path, $suffix) = fileparse($file, ".muse");
    unless ($suffix) {
        warn "$file is not a muse file!";
        return;
    }

    unless ($name =~ m/^[0-9a-z]+[0-9a-z-]*[0-9a-z]+$/) {
        warn "$file has not a sane name!";
        return;
    }
    my @dirs = File::Spec->splitdir($path);
    @dirs = grep { $_ ne '' } @dirs;
    unless (@dirs >= 2) {
        warn "$file is not in the correct path!";
        return;
    }
    my @relpath = ($dirs[$#dirs-1], $dirs[$#dirs]);
    unless ($relpath[0] =~ m/^[0-9a-z]$/s and
            $relpath[1] =~ m/^[0-9a-z]{2}$/s) {
        warn "$file is not in the correct path:" . Dumper(\@relpath);
        return;
    }


    # scan the directives;
    my $directives = muse_fast_scan_header($file, 'html');
    unless ($directives && %$directives) {
        # title is mandatory?
        warn "$file couldn't be parsed by muse_fast_scan_header\n";
        return;
    }
    # just to be sure, check that the keys have not an underscore

    foreach my $k (keys %$directives) {
        die "Got $k directive with underscore in $file" unless index($k, '_') < 0;
    }

    # we don't get clashes with the parsing of the muse file because
    # directives have not underscors in them

    my %out = (
               %$directives,
               f_path => $path,
               f_name => $name,
               f_archive_rel_path => File::Spec->catdir(@relpath),
               f_timestamp => get_mtime($file),
               f_full_path_name  => $file,
              );

    return \%out;
}


sub get_mtime {
  my $file = shift;
  my @stats = stat($file);
  my $mtime = $stats[9];
  return $mtime;
}




1;
