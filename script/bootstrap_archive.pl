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
use POSIX qw/nice/;
use Getopt::Long;

my $refresh;

GetOptions (refresh => \$refresh) or die;

# be nice
nice(19);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $schema = AmuseWikiFarm::Schema->connect('amuse');

print "DB loaded, starting up\n";

my @codes;
foreach my $s ($schema->resultset('Site')->all) {
    print $s->id . " " . $s->vhosts->first->name . "\n";
    push @codes, $s->id;
}

if (@ARGV) {
    @codes = @ARGV;
}

foreach my $code (@codes) {
    my $site = $schema->resultset('Site')->find($code);
    if ($site) {
        print "Processing $code\n";
    }
    else {
        warn "Site code $code not found in the database. Skipping...\n";
        next;
    }
    # with --refresh, just check
    if ($refresh) {
        $site->update_db_from_tree;
    }
    # without, do a full import
    else {
        my @files = sort keys %{ $site->repo_find_files };
        $site->compile_and_index_files(\@files);
    }
}
