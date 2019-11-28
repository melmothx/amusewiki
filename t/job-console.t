#!perl

use strict;
use warnings;

use utf8;
use Test::More tests => 40;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0jobscon0');

$site->update({ secure_site => 0 });

my $user = $site->update_or_create_user({
                                         username => 'jobadmin',
                                         password => 'pallino'
                                        });

$user->set_roles([{ role => 'librarian' }]);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $other_id = $schema->resultset('Site')->find('0blog0')->jobs->enqueue(testing => {})->id;

my $j = $site->jobs->enqueue(testing => {});

{
    is $schema->resultset('Job')->job_status_count->first->{status}, 'pending';
    is $schema->resultset('Job')->job_status_count->first->{job_count}, 2;
    is $site->jobs->job_status_count->first->{job_count}, 1;

    my $pj = $site->jobs->enqueue(testing => {});
    $pj->update({ status => 'taken' });
    my $data = $schema->resultset('Job')->monitoring_data;
    ok scalar(@{$data->{active_jobs}}), "Found active jobs"  or diag Dumper($data);
    ok $data->{status}->{taken}  or diag Dumper($data);
    is $data->{stuck_jobs}, 0  or diag Dumper($data);
    $pj->dispatch_job;

    $data = $schema->resultset('Job')->monitoring_data;
    is $data->{status}->{taken}, 0 or diag Dumper($data);
    ok $data->{last_completed_job} or diag Dumper($data);
    ok $data->{jobber_ok} or diag Dumper($data);
    $pj->delete;
}

my $jid = $j->id;
$j->dispatch_job;
$j->update({ status => 'failed' });
login();
$mech->get('/tasks/all/show');
is $mech->status, 403, "librarian can't access the jobs";
$mech->get('/admin/jobs/show');
is $mech->status, 403, "librarian can't access the jobs";
logout();

$user->set_roles([{ role => 'admin' }]);
login();
$mech->get_ok('/tasks/all/source-ajax');
diag $mech->content;
$mech->content_like(qr{"id": *"?\Q$jid\E\b"?});
$mech->get_ok('/tasks/all/show');
ok $mech->submit_form(with_fields => { reschedule_job => $jid });
$mech->content_contains("1 jobs rescheduled") or die $mech->content;

ok $mech->submit_form(with_fields => { delete_job => $jid });
$mech->content_contains("1 jobs deleted");
logout();

$j = $site->jobs->enqueue(testing => {});
$jid = $j->id;
$j->dispatch_job;

$user->set_roles([{ role => 'root' }]);
login();
$mech->get_ok('/admin/jobs/source-ajax');
diag $mech->content;
$mech->content_like(qr{"id": *"?\Q$jid\E\b});

$j->update({ status => 'failed' });
$mech->get_ok('/admin/jobs/show');

ok $mech->submit_form(with_fields => { reschedule_job => $jid });
is $j->discard_changes->status, 'pending';
is $j->started, undef;
is $j->completed, undef;
is $j->produced, undef;
is $j->errors, undef;
$mech->content_contains("1 jobs rescheduled");

ok $mech->submit_form(with_fields => { delete_job => $jid });
$mech->content_contains("1 jobs deleted");

$mech->get_ok('/admin/jobs/source-ajax');
diag $mech->content;
$mech->content_unlike(qr{"id": *"?\Q$jid\E\b});

$mech->get_ok('/admin/jobs/monitor');
$mech->content_contains('active_jobs');
diag $mech->content;

logout();



sub login {
    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => 'jobadmin', __auth_pass => 'pallino' });
}

sub logout {
    $mech->get_ok('/logout');
}
