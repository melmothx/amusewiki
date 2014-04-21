#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use FindBin qw/$Bin/;
use File::Basename;
use File::Find;
use File::Spec::Functions qw/catdir/;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $schema = AmuseWikiFarm::Schema->connect('amuse');

print "DB loaded, starting up\n";

foreach my $s ($schema->resultset('Site')->all) {
    print $s->id . " " . $s->vhosts->first->name . "\n";
}

my @codes = @ARGV;

foreach my $code (@codes) {
    my $site = $schema->resultset('Site')->find($code);
    unless ($site) {
        warn "Site code $code not found in the database. Skipping...\n";
        next;
    }

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
          }, $site->repo_root);


    # print Dumper(\@files);
    foreach my $file (sort @files) {
        print "indexing $file\n";
        $site->index_file($file) || print "Ignored $file\n";
    }
    # set the sorting
    print "Updating the sorting for $code\n";
    $site->collation_index;
}
