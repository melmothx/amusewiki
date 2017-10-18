#!perl

use strict;
use warnings;
use Test::More tests => 32;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Jobber;
my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $jobber = AmuseWikiFarm::Utils::Jobber->new(schema => $schema);

$schema->resultset('Job')->delete;
$schema->resultset('Job')->enqueue_global_job('hourly_job');
$schema->resultset('Job')->enqueue_global_job('hourly_job');

my $job;
foreach my $sec (1..5) {
    my ($new_job) = $jobber->main_loop;
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

my $site = create_site($schema, '0cformats1');
foreach my $i (1..10) {
    $site->custom_formats->create({ format_name => "Format name $i"});
}

{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . ("\n\n some more text for the masses\n" x 25));
    $rev->commit_version;
    $rev->publish_text;
}

# with 3 parallels, we need 3 loops + 1 for the last + 1 for the static indexes

ok $site->jobs->pending->build_custom_format_jobs->count;
foreach my $i (1..5) {
    diag "Loop $i of the jobber\n";
    my (@jobs) = $jobber->main_loop;
    if ($i < 4) {
        is scalar(@jobs), 3;
        ok !$jobs[0]->non_blocking;
        ok $jobs[1]->non_blocking;
        ok $jobs[2]->non_blocking;
    }
    else {
        is scalar(@jobs), 1;
        ok !$jobs[0]->non_blocking;
    }
}
sleep 2;
ok !$site->jobs->pending->build_custom_format_jobs->count, "queue exausted";
