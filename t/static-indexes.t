#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file/;

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

use AmuseWikiFarm::Archive::StaticIndexes;
use Data::Dumper;
use Test::More;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $indexes = $site->static_indexes_generator;

ok($indexes);

my @targets = (qw/titles topics authors/);

my @files;
foreach my $method (map { $_ . '_file' } @targets) {
    my $file = $indexes->$method;
    ok ($file);
    diag $file;
    if (-f $file) {
        diag "removing $file";
        unlink $file or die "Cannot remove $file $!";
    }
    push @files, $file;
}

foreach my $method (map { 'create_' . $_ } @targets) {
    ok ($indexes->$method, "$method returns something");
}

$indexes->generate;

foreach my $file (@files) {
    ok (-f $file, "$file was generated");
}


done_testing;
