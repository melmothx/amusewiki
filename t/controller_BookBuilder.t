use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::BookBuilder;

my $host = { host => 'blog.amusewiki.org' };

ok( request('/bookbuilder', $host)->is_success, 'Request should succeed' );
done_testing();
