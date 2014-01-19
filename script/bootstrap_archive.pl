#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Basename;
use File::Spec;
use File::Find;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Model::DB;
use Text::Amuse::Functions qw/muse_fast_scan_header/;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $db = AmuseWikiFarm::Model::DB->new;

print "DB loaded, starting up\n";

foreach my $s ($db->resultset('Site')->all) {
    print $s->site_id . " " . $s->name . "\n";
}

my @archives = @ARGV;

my %title_columns = map { $_ => 1 } $db->resultset('Title')->result_source->columns;

foreach my $archive (@archives) {
    my $code = basename($archive);
    print "Scanning $archive with code $code\n";
    die "Wrong code or directory $code" unless ($code =~ m/^[a-z]{2,50}+$/);
    my @files;
    find (sub {
              my $file = $_;
              return unless -f $file;
              return unless $file =~ m/\.muse$/;
              
              return unless index($File::Find::dir, '.git') < 0;
              push @files, $File::Find::name;
              
          }, $archive);
    # print Dumper(\@files);
    foreach my $file (@files) {
        die "$file not found!" unless -f $file;
        my $details = parse_muse_file($file);
        unless ($details) {
            warn "Found wrong file $file for $archive ($code)\n";
            next;
        }
        $details->{site_id} = $code;
        $details->{uri} = $details->{f_name};
        # print Dumper($details);

        # ready to store into titles?
        my %insertion;
        # lower case the keys
        foreach my $col (keys %$details) {
            my $db_col = lc($col);
            if ($title_columns{$db_col}) {
                $insertion{$db_col} = delete $details->{$col};
            }
        }

        # TODO
        delete $details->{SORTauthors};
        delete $details->{SORTtopics};

        # TODO fixed categories, to lookup in tables, space separated
        delete $details->{cat};

        my $title_order_by = delete $details->{LISTtitle};
        if (defined $title_order_by and length($title_order_by)) {
            $insertion{list_title} = $title_order_by;
        }
        else {
            $title_order_by = $insertion{title};
            if (defined $title_order_by and
                and $title_order_by =~ m/\w/) {
                $title_order_by =~ s/^[\W]+//;
                $insertion{list_title} = $title_order_by;
            }
        }

        # check if the title exists
        unless ($insertion{title}) {
            warn "$file has no title! Setting deletion\n";
            $insertion{deleted} ||= "Missing title";
        }

        if (%$details) {
            warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
        }
        print "Inserting data for $file\n";
        $db->resultset('Title')->create(\%insertion);
    }
}

sub parse_muse_file {
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
