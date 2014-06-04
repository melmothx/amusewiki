#!/usr/bin/env perl

use strict;
use warnings;

use AmuseWikiFarm::Archive::Xapian;
use AmuseWikiFarm::Schema;
use File::Temp;
use File::Spec;
use Test::More tests => 3;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;

my $testdir = File::Temp->newdir;
my $basedir = $testdir->dirname;

ok( -d $basedir);

mkdir File::Spec->catdir($basedir, 'xapian');


my $xapian = AmuseWikiFarm::Archive::Xapian->new(
                                                 code => '0test0',
                                                 locale => 'en',
                                                 basedir => $basedir,
                                                );

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my @texts = $schema->resultset('Site')->find('0test0')->titles->published_texts;


foreach my $t (@texts) {
    $xapian->index_text($t);
}

# drop the object and flush it
$xapian = undef;

$xapian = AmuseWikiFarm::Archive::Xapian->new(
                                              code => '0test0',
                                              locale => 'en',
                                              basedir => $basedir,
                                             );



my ($total, @results) = $xapian->search('"XXXX"');

is($total, 1);
ok(@results == 1, "Found 1 result with XXXX");



