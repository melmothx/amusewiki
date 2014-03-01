use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Admin;

my $res;
$res = request('/admin/debug_site_id', { host => 'test.amusewiki.org' });
is($res->decoded_content, '0test0 en');
$res = request('/admin/debug_site_id', { host => 'blog.amusewiki.org' });
is($res->decoded_content, '0blog0 hr');

done_testing();
