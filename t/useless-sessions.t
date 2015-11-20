#!perl
use strict;
use warnings;
use Test::More tests => 18;
use Data::Dumper;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

for (1..3) {
    foreach my $path ('/', '/library', '/category/author', '/category/topic', '/login', '/human') {
        my $res = $mech->get($path);
        ok(!$res->header('Set-Cookie'), "No cookie set on $path") or diag $res->header('Set-Cookie');
    }
}

