#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Cwd;


use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $queue = $schema->resultset('Job');
my $cwd = getcwd();
print "Starting job server loop in $cwd\n";

while (1) {
    chdir $cwd or die $!;
    sleep 3;
    my $job = $queue->dequeue;
    next unless $job;
    print "Dispatching ", $job->id, " ", $job->status, " => ", $job->task, "\n";
    $job->dispatch_job;
    chdir $cwd or die $!;
}

