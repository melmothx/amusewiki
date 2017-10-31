#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Schema;
use Test::More tests => 67;
use File::Spec::Functions;
use Cwd;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/start_jobber stop_jobber run_all_jobs/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
ok ($site, "site found");

my $text = $site->titles->published_texts->first;
$site->jobs->enqueue(rebuild => { id => $text->id }, 15);
sleep 1;
$site->jobs->enqueue(testing => { id => $text->id }, 10);

my @exts = (qw/pdf epub zip tex html/);
my %ts;
foreach my $ext (@exts) {
    my $file = $text->filepath_for_ext($ext);
    ok (-f $file, "$file exists");
    $ts{$ext} = (stat($file))[9];
}

{
    my $job = $site->jobs->dequeue;
    is $job->task, 'testing', "First dispatched job is the higher priority";
    $job->dispatch_job;
    is $job->status, 'completed';
}
{
    my $job = $site->jobs->dequeue;
    is $job->task, 'rebuild';
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
    is $job->produced, $text->full_uri;
    my $jlogs = $job->logs;
    $job->delete;
    run_all_jobs($schema);
    foreach my $ext (@exts) {
        like $jlogs, qr/(Created|Scheduled) .*\.\Q$ext\E/;
        ok (-f $text->filepath_for_ext($ext), "$ext exists");
        my $newts = (stat($text->filepath_for_ext($ext)))[9];
        ok ($newts > $ts{$ext}, "$ext updated");
    }
}

start_jobber($schema);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


$mech->get_ok('/');
$mech->get($text->full_rebuild_uri);
is $mech->status, 401;
$mech->submit_form(form_id => 'login-form',
                   fields => { __auth_user => 'root',
                               __auth_pass => 'root',
                             });
my $check_status_url = $mech->uri->path;
like $mech->uri->path, qr{/tasks/status/};
sleep 30;
$mech->get_ok($mech->uri->path);
$mech->content_contains('Job rebuild finished');
my $uri = $text->uri;
$mech->content_like(qr{Scheduled .* \Q$uri\E\.pdf});
$mech->get_ok($text->full_uri . '.pdf');

stop_jobber();

$site->bulk_jobs->delete_all;
ok(!$site->bulk_jobs->count, "No bulk jobs so far");

$mech->get_ok('/tasks/rebuild');

$mech->submit_form(form_id => 'site-rebuild-form',
                   button => 'rebuild');

is($site->bulk_jobs->count, 1, "bulk job created");
my $bulk = $site->bulk_jobs->first;

$mech->get_ok('/tasks/job/' . $bulk->bulk_job_id . '/show');
$mech->content_contains('/tasks/rebuild');
# check button
$mech->content_contains('name="cancel"');

$mech->get_ok('/tasks/job/' . $bulk->bulk_job_id . '/ajax');
diag $mech->content;
$mech->get_ok('/tasks/rebuild');

ok $bulk->jobs->count, "bulk job has jobs";
ok !$bulk->completed, "job is not completed";
{
    my $test_job = $bulk->jobs->first;
    ok defined($test_job->bulk_job_id);
    ok $test_job->dispatch_job;
    is $test_job->status, 'completed';
    is $test_job->username, 'root';
    diag $test_job->logs;
    ok $test_job->logs;
    my $check_ext = '/tasks/status/' . $test_job->id;
    $mech->get_ok($check_ext);
    $mech->get_ok('/logout');
    $mech->get($check_ext);
    is $mech->status, 404;
    $mech->get($check_status_url);
    is $mech->status, 404;
}
$bulk->discard_changes;
ok $bulk->eta;
ok $bulk->eta_locale;

$bulk->jobs->update({ status => 'failed' });
$bulk->discard_changes;
ok (!$bulk->completed, "completed not set because of direct db crushing");
$bulk->jobs->first->update({ status => 'completed' });
$bulk->discard_changes;
ok ($bulk->started);
ok ($bulk->completed);
is $bulk->status, 'completed', "job is completed when all the jobs are completed or failed";
$bulk->delete;

$bulk = $site->rebuild_formats;
$bulk->discard_changes;
ok ($bulk->is_rebuild) or diag "Task is " . $bulk->task;
ok (!$bulk->started);
ok (!$bulk->completed);
$bulk->jobs->first->update({ status => 'taken' });
$bulk->discard_changes;
ok ($bulk->started);
ok (!$bulk->completed);
$bulk->abort_jobs;
ok ($bulk->started);
ok ($bulk->completed);
ok (!$bulk->jobs->pending->count, "No pending jobs after aborting");
ok $bulk->jobs->search({ errors => 'Bulk job aborted', status => 'completed' })->count;
$site->bulk_jobs->abort_all;
$site->jobs->delete_all;



