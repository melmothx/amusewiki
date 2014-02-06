#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'AmuseWikiFarm';

ok( request('/', { host => 'test.amusewiki.org' })->is_success, 'Request should succeed' );

done_testing();
