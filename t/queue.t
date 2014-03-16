#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Queue;
use JSON qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $queue = AmuseWikiFarm::Archive::Queue->new(dbic => $schema);

ok($queue);

my $late = $queue->add_job(testing => '0blog0' => { this => 0, test => 'òć' }, 9);

sleep 1;

my $id = $queue->add_job(testing => '0blog0' => { this => 0, test => 'òć' }, 5);

ok($id, "Id is $id");

my $job = $queue->get_job;

ok($job);
is($job->id, $id);
is($job->status, 'taken');

is_deeply(from_json($job->payload), { this  => 0, test => 'òć' });

sleep 1;

# empty the jobs

while (my $j = $queue->get_job) {
    diag "Got stale job " . $j->id;
}

done_testing;

