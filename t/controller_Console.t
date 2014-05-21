use strict;
use warnings;
use Test::More;
use Data::Dumper;

unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => '0pull0.amusewiki.org');

$mech->get_ok('/console');
is $mech->response->base->path, '/login', "Denied access to not logged in";

done_testing();
