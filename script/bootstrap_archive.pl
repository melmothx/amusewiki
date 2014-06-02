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
    unless ($site) {
        warn "Site code $code not found in the database. Skipping...\n";
        next;
    }
    $site->update_db_from_tree;
}
