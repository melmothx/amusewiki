use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


$mech->get_ok('/opds');
print $mech->content;
diag $mech->content_type;

$mech->get_ok('/opds/titles');
print $mech->content;
diag $mech->content_type;


done_testing();

