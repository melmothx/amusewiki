use strict;
use warnings;
use Test::More;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 4;
use Test::WWW::Mechanize::Catalyst;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

$mech->get_ok('/utils/import');
ok($mech->form_with_fields('html_body'));
$mech->field(html_body => '<p><b>Ciao</b></p><p>Hullo</p>');
$mech->click;
$mech->content_contains('muse_body');
$mech->content_contains("Ciao&lt;/strong&gt;\n\nHullo");




