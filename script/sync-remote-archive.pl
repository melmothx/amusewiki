#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;

my ($site_id, $remote) = @ARGV;
die "Missing site_id and/or remote" unless $site_id && $remote;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find($site_id);
die "Site $site not found" unless $site;
my $job = $site->jobs->git_action_add({ remote => $remote,
                                          action => 'fetch' });
my $id = $job->discard_changes->id;

print "Job id is tasks/status/$id\n";

# then loop and pool

my $maxloop = 100;
while ($job->status ne 'completed' and $job->status ne 'failed') {
    $maxloop--;
    if ($maxloop < 0) {
        print "Waiting for job completion timed out\n";
        last;
    }
    sleep 10;
    $job = $schema->resultset('Job')->find($id);

}

print join("\n", map { $_ || '' }
           $job->id , $job->site_id, $job->status,
           $job->produced,
           $job->errors, $job->logs);
