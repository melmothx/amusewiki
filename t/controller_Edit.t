use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Edit;

ok( request('/edit')->is_success, 'Request should succeed' );
done_testing();
