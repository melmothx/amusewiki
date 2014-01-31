#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Basename;
use File::Find;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Model::DB;
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $db = AmuseWikiFarm::Model::DB->new;

print "DB loaded, starting up\n";

foreach my $s ($db->resultset('Site')->all) {
    print $s->site_id . " " . $s->name . "\n";
}

my @archives = @ARGV;

my %title_columns = map { $_ => 1 } $db->resultset('Title')->result_source->columns;
print Dumper(\%title_columns);

foreach my $archive (@archives) {
    my $code = basename($archive);
    print "Scanning $archive with code $code\n";
    die "Wrong code or directory $code" unless ($code =~ m/^[a-z]{2,50}+$/);
    my @files;
    find (sub {
              my $file = $_;
              return unless -f $file;
              return unless index($File::Find::dir, '.git') < 0;

              if ($file =~ m/\.muse$/) {
                  push @files, $File::Find::name;
              }
              if ($file =~ m/([0-9a-z-]+?)(\.(a4|lt))?\.pdf$/) {
                  # don't save it if exists a muse file
                  return if (-f $1 . '.muse');
              }
              if ($file =~ m/\.(pdf|png|jpe?g)$/) {
                  push @files, $File::Find::name;
              }
          }, $archive);
    # print Dumper(\@files);
    foreach my $file (@files) {
        die "$file not found!" unless -f $file;
        my $details = muse_file_info($file, $code);

        unless ($details) {
            warn "Found wrong file $file for $archive ($code)\n";
            next;
        }

        if ($details->{f_suffix} ne '.muse') {
            print "Inserting data for attachment $file\n";
            $db->resultset('Attachment')->update_or_create($details);
            next;
        }

        # ready to store into titles?
        my %insertion;
        # lower case the keys
        foreach my $col (keys %$details) {
            my $db_col = lc($col);
            if ($title_columns{$db_col}) {
                $insertion{$db_col} = delete $details->{$col};
            }
        }

        my $parsed_cats = delete $details->{parsed_categories};
        if (%$details) {
            warn "Unhandle directive in $file: " . join(", ", %$details) . "\n";
        }
        print "Inserting data for $file\n";
        # TODO: see if we have to update the insertion
        my $title = $db->resultset('Title')->update_or_create(\%insertion);
        if ($parsed_cats && @$parsed_cats) {
            $title->set_categories($parsed_cats);
        }
    }
}
