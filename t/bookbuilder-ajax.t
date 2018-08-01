use strict;
use warnings;
use Test::More tests => 10;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use JSON::MaybeXS;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$site->update({ bb_page_limit => 1000 });

$mech->get_ok('/?__language=en');
$mech->get('/bookbuilder');
is $mech->status, 401;
$mech->submit_form(with_fields => { __auth_human => 'January' });
$mech->get_ok('/bookbuilder/add/first-test');

$mech->get_ok('/bookbuilder/add/first-test?ajax=1');
is decode_json($mech->content)->{total}, 2;

$mech->get_ok('/bookbuilder/add/x-first-test?ajax=1');
is decode_json($mech->content)->{total}, 2;
ok decode_json($mech->content)->{error_msg};
diag $mech->content;

$mech->get_ok('/bookbuilder/ajax/titles');
is_deeply decode_json($mech->content), { titles => [qw/first-test first-test/] };

$site->update({ bb_page_limit => 10 });
