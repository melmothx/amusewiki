#!perl
use strict;
use warnings;
use Test::More tests => 15;
use Data::Dumper;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;

use Test::WWW::Mechanize::Catalyst;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
$site->update({ mode => 'openwiki'});

$mech->get_ok('/');

for (1..3) {
    foreach my $path ('/', '/library', '/category/author', '/category/topic') {
        my $res = $mech->get($path);
        ok(!$res->header('Set-Cookie'), "No cookie set on $path") or diag $res->header('Set-Cookie');
    }
}

{
    my $res = $mech->get('/login');
    ok($res->header('Set-Cookie'), "Cookie set on login");
    $mech->get('/publish/all');
    is $mech->status, 403;
}

$site->update({ mode => 'modwiki'});


