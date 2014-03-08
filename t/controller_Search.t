use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Search;

my $host = { host => 'test.amusewiki.org' };

ok( request('/search', $host)->is_success, 'Request should succeed' );
done_testing();
