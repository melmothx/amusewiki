#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Cwd;


use AmuseWikiFarm::Schema;

my $harakiri;

sub do_harakiri {
    $harakiri = 1;
}

$SIG{'TERM'} = 'do_harakiri';
$SIG{'INT'}  = 'do_harakiri';
$SIG{'KILL'} = 'do_harakiri';


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $queue = $schema->resultset('Job');
my $cwd = getcwd();
print "Starting job server loop in $cwd\n";

while (1) {
    if ($harakiri) {
        print "Exiting as requested\n";
        exit;
    }
    chdir $cwd or die $!;
    sleep 3;
    my $job = $queue->dequeue;
    next unless $job;
    print "Starting job on " . localtime() . "\n";
    print "Dispatching ", $job->id, " ", $job->status, " => ", $job->task, "\n";
    $job->dispatch_job;
    print "Job finished on " . localtime() . "\n";
    chdir $cwd or die $!;
}

