#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 20;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use File::Slurp qw/write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0sf0';
my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");



my $basedir = $site->path_for_site_files;
like $basedir, qr/\Q$site_id\E.\Qsite_files\E/ or die $basedir;
mkdir $basedir or die "Cannot create $basedir !";

my @good = ("test.txt");
my @bad = (".tryme.torrent", "test me.exe", "hullo_therer.ciao");


foreach my $file (@good, @bad) {
    my $testfile = catfile($basedir, $file);
    write_file($testfile, "xxx\n");
    ok (-f $testfile, "$testfile found");
}

foreach my $good_one (@good) {
    $mech->get_ok("/sitefiles/$site_id/$good_one");
}

foreach my $bad_one (@bad) {
    $mech->get("/sitefiles/$site_id/$bad_one");
    is $mech->status, '404', "/sitefiles/$site_id/$bad_one not found";
    $mech->get("/sitefiles/$site_id/subdir/$bad_one");
    is $mech->status, '404', "/sitefiles/$site_id/subdir/$bad_one not found";
}

# default layout, so check the favicon

$mech->get_ok('/');
$mech->content_lacks('favicon.ico');
$mech->content_lacks('local.css');
$mech->content_lacks('local.js');

# create them and recheck

foreach my $localf (qw/favicon.ico local.css local.js/) {
    my $testfile = catfile($basedir, $localf);
    write_file($testfile, "xxx\n");
}

foreach my $localf (qw/favicon.ico local.css local.js/) {
    $mech->get('/');
    my $uri = "/sitefiles/$site_id/$localf";
    $mech->content_contains(qq{$localf"});
    $mech->get_ok($uri);
}
