use strict;
use warnings;
use Test::More tests => 5;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };



unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

ok($mech);

$mech->get_ok( '/special/index' );
$mech->content_contains('$("#amw-latest-entries-special-page").load("/latest',
                        "Found the latest entries");
$mech->get_ok('/latest');
$mech->content_contains('Zu A Second test', "Found the latest entries");
