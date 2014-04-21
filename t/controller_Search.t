use strict;
use warnings;
use Test::More tests => 2;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Search;

my $host = { host => 'test.amusewiki.org' };

my $res = request('/search?query=a', $host);
ok ($res->is_success);

like $res->decoded_content, qr/second-test/, "Found a text";

