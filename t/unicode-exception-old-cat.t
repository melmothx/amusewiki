#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 14;
use Test::WWW::Mechanize::Catalyst;
use Encode;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

for (1..2) {
    $mech->get_ok('/latest');
    $mech->get('/library/%E2%C3%83%C6%92%C3%8');
    is ($mech->status, '400');
    is ($mech->content, "Bad Unicode data");
  SKIP: {
        # nothing we can do at this point
        skip "Query params are mangled with latest catalysts", 2
          if $Catalyst::VERSION > 5.90079;
        $mech->get('/?p=%E2');
        is ($mech->status, '400');
        is ($mech->content, "Bad Unicode data");
    }
    $mech->post('/search', Content => 'query=%E2');
    is ($mech->status, '400');
    is ($mech->content, "Bad Unicode data");
    $mech->post('/search%E3?p=%E4', Content => 'query=%E2');
}

