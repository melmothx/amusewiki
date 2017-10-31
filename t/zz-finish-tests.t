#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Cwd;
use File::Spec::Functions qw/catdir catfile/;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
ok ($schema);
foreach my $job ($schema->resultset('Job')->all) {
    $job->delete;
}
foreach my $rev ($schema->resultset('Revision')->all) {
    $rev->delete;
}
