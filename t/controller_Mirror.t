#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 28;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my @paths = (qw[
                   authors.html 
                   titles.html topics.html site_files/navlogo.png 
                   site_files/favicon.ico
                   site_files/__static_indexes/fonts/FontAwesome.otf
              ]);

$site->update({
               cgit_integration => 0,
               mode => 'modwiki',
              });

foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}

$site->update({ cgit_integration => 1 });
ok $site->cgit_integration;

foreach my $path (@paths) {
    $mech->get_ok("/mirror/$path");
}

$mech->get_ok("/mirror");
is $mech->uri->path, '/mirror/titles.html';
$mech->get_ok("/mirror/");
is $mech->uri->path, '/mirror/titles.html';


foreach my $bad (qw[.git .gitignore .. . ../../../hello blaa/../hello ]) {
    $mech->get("/mirror/$bad");
    is $mech->status, 400;
}


$site->update({ mode => 'private' });
ok $site->cgit_integration;

foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}

$site->update({
               cgit_integration => 0,
               mode => 'modwiki',
              });
