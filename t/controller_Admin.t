use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Admin;

ok( request('/admin')->is_success, 'Request should succeed' );
my $res;
$res = request('/admin/debug_site_id', { host => 'fi.anarhija.net' });
is($res->decoded_content, 'fi');
$res = request('/admin/debug_site_id', { host => 'balblalkkasdf.net' });
is($res->decoded_content, 'default');

done_testing();
