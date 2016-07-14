#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 2;
use Test::WWW::Mechanize::Catalyst;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

$mech->get('/library/%E2%C3%83%C6%92%C3%8');
is ($mech->status, '400');
is ($mech->content, "Bad Unicode data");

