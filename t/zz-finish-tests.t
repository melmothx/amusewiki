#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Cwd;
use File::Spec::Functions qw/catdir catfile/;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;


my $init = catfile(getcwd(), qw/script jobber.pl/);

ok(system($init, 'stop') == 0);

# cleanup

my $schema = AmuseWikiFarm::Schema->connect('amuse');
foreach my $job ($schema->resultset('Job')->all) {
    $job->delete;
}
foreach my $rev ($schema->resultset('Revision')->all) {
    $rev->delete;
}
