use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Category;

ok( request('/category')->is_success, 'Request should succeed' );
done_testing();
