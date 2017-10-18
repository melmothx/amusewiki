#!perl

use strict;
use warnings;
use Test::More tests => 14;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Jobber;
my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $jobber = AmuseWikiFarm::Utils::Jobber->new(schema => $schema);

$schema->resultset('Job')->delete;
$schema->resultset('Job')->enqueue_global_job('hourly_job');
$schema->resultset('Job')->enqueue_global_job('hourly_job');

my $job;
foreach my $sec (1..5) {
    my $new_job = $jobber->main_loop;
    if ($sec < 5) {
        ok ($new_job);
        is $new_job->status, 'pending';
        # check previous job;
    }
    else {
        ok !$new_job or die Dumper($new_job->as_hashref);
    }
    if ($sec > 1) {
        is $job->discard_changes->status, 'completed';
    }
    $job = $new_job;
}
is $schema->resultset('Job')->search({ status => 'completed' })->count, 4;

