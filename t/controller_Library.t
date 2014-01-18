use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Library;

ok( request('/library')->is_success, 'Request should succeed' );
done_testing();
