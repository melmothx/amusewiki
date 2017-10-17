#!perl

use strict;
use warnings;
use Test::More tests => 5;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
my $schema = AmuseWikiFarm::Schema->connect('amuse');

$schema->resultset('Job')->delete;
$schema->resultset('Job')->enqueue_global_job('daily_job');
$schema->resultset('Job')->enqueue_global_job('hourly_job');

my $job = $schema->resultset('Job')->dequeue;
ok $job;
$job->dispatch_job;
foreach my $m (qw/status started completed logs/) {
    ok($job->$m, "$m is ok") and diag $job->$m;
}
$schema->resultset('Job')->fail_stale_jobs;
