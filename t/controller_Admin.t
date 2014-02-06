use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Admin;

my $res;
$res = request('/admin/debug_site_id', { host => 'test.amusewiki.org' });
is($res->decoded_content, 'test en');
$res = request('/admin/debug_site_id', { host => 'blog.amusewiki.org' });
is($res->decoded_content, 'blog hr');

done_testing();
