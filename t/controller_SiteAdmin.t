use strict;
use warnings;
use Test::More;


use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::SiteAdmin;

ok( request('/siteadmin')->is_success, 'Request should succeed' );
done_testing();
