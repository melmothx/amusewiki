#!/usr/bin/env perl

# test which always passes, but which has the site effect to bootstrap
# the archives needed for the tests. TODO Activate this properly
use strict;
use warnings;
use Test::More;

use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

ok($schema);

foreach my $site ($schema->resultset('Site')->all) {
    # $site->bootstrap_archive;
}

done_testing;

