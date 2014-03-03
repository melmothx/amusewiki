#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use File::Basename;
use File::Find;
use File::Spec::Functions qw/catdir/;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive;
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $db = AmuseWikiFarm::Schema->connect('amuse');

print "DB loaded, starting up\n";

foreach my $s ($db->resultset('Site')->all) {
    print $s->id . " " . $s->vhosts->first->name . "\n";
}

my @codes = @ARGV;

foreach my $code (@codes) {

    # checking
    unless ($code =~ m/^[a-z0-9]{2,8}$/) {
        warn "Wrong code $code, see README.txt for naming convention. Skipping...\n";
        next;
    }
    my $locale;
    if (my $site = $db->resultset('Site')->find($code)) {
        $locale = $site->locale;
    }
    else {
        warn "Site code $code not found in the database. Skipping...\n";
        next;
    }

    my $archive = AmuseWikiFarm::Archive->new(repo => catdir(repo => $code),
                                              code => $code,
                                              locale => $locale,
                                              dbic => $db,
                                              xapian => catdir(xapian => $code));

    # find the file
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
          }, catdir(repo => $code));
    # print Dumper(\@files);
    foreach my $file (@files) {
        print "indexing $file\n";
        $archive->index_file($file) || print "Ignored $file\n";
    }
    # set the sorting
    print "Updating the sorting for $code\n";
    $archive->collation_index;
}
