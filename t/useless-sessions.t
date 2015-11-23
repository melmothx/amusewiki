#!perl
use strict;
use warnings;
use Test::More tests => 22;
use Data::Dumper;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;

use Test::WWW::Mechanize::Catalyst;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
$site->update({ mode => 'openwiki'});

for (1..3) {
    foreach my $path ('/', '/library', '/category/author', '/category/topic', '/login', '/human', '/publish/all') {
        my $res = $mech->get($path);
        ok(!$res->header('Set-Cookie'), "No cookie set on $path") or diag $res->header('Set-Cookie');
    }
}

$mech->get('/publish/all');
is ($mech->uri->path, '/human', "Not human in '/human' from publish/all");

$site->update({ mode => 'modwiki'});


