use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };



unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

ok($mech);

$mech->get_ok( '/special/index' );
done_testing();
