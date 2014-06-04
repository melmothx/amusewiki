#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 16;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use AmuseWikiFarm::Schema;
use JSON qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $j = $site->jobs->enqueue(testing => {});

is $j->site->id, '0blog0';

eval {
    $schema->resultset('Job')->enqueue(testing => {});
};

ok("Adding jobs without a site triggers an exception");

my $late = $site->jobs->enqueue(testing => { this => 0, test => 'òć' }, 9);

sleep 1;

my $highpriority = $site->jobs->enqueue(testing => { this => 0, test => 'òć' }, 5);
my $id = $highpriority->id;

ok($id, "Id is $id");

my $job = $site->jobs->dequeue;

ok($job);
is($job->id, $id);
is($job->status, 'taken');
ok($job->log_file, "Found log file " . $job->log_file);
like $job->log_file, qr/\.log$/;

is_deeply(from_json($job->payload), { this  => 0, test => 'òć' });

my $json = $job->as_json;
ok($json);

my $struct = from_json($json);

is_deeply($struct->{payload},  { this  => 0, test => 'òć' });
is $struct->{task}, 'testing';
is $struct->{status}, 'taken';
is $struct->{site_id}, '0blog0';
is $struct->{priority}, 5;
is $struct->{id}, $id;

# empty the jobs

while (my $j = $site->jobs->dequeue) {
    diag "Got stale job " . $j->id;
}

