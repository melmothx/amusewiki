#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 59;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
# clear
$schema->resultset('Job')->delete;

my $init = catfile(getcwd(), qw/script jobber.pl/);
# kill the jobber
system($init, 'stop');

my $othersite = $schema->resultset('Site')->find('0test0');

my $j = $site->jobs->enqueue(testing => {});

is $j->site->id, '0blog0';
is $j->username, undef, "Username is undef";
is $j->committer_username, "anonymous";
is $j->committer_name, "Anonymous";
is $j->committer_mail, "anonymous\@blog.amusewiki.org";
{
    my $jx = $site->jobs->enqueue(testing => {}, "ùàà òò");
    is $jx->username, "uaaoo";
    is $jx->committer_username, "uaaoo";
    is $jx->committer_name, "Uaaoo";
    is $jx->committer_mail, "uaaoo\@blog.amusewiki.org";
    $jx->update({ username => undef });
    is $j->committer_username, "anonymous";
    is $j->committer_name, "Anonymous";
    is $j->committer_mail, "anonymous\@blog.amusewiki.org";
    $jx->update({ username => "    ùàà \n òò \r    " });
    is ($jx->username,        "    ùàà \n òò \r    ");
    is $jx->committer_username, "uaaoo";
    is $jx->committer_name, "Uaaoo";
    is $jx->committer_mail, "uaaoo\@blog.amusewiki.org";
    $jx->delete;
    $jx = $site->jobs->enqueue(testing => {}, "pinco.pallino");
    is $jx->username, "pinco.pallino";
    is $jx->committer_username, "pinco.pallino";
    is $jx->committer_name, "Pinco.pallino";
    is $jx->committer_mail, "pinco.pallino\@blog.amusewiki.org";
    $jx->delete;
}

eval {
    $schema->resultset('Job')->enqueue(testing => {});
};

ok($@, "Adding jobs without a site triggers an exception: $@");

sleep 1;

$site->jobs->enqueue(testing => { this => 0, test => 'òć' });

sleep 1;

my $highpriority = $site->jobs->enqueue(testing_high => { this => 0, test => 'òć' });
my $id = $highpriority->id;

ok($id, "Id is $id");

my $job = $site->jobs->dequeue;
$job->dispatch_job;
ok($job);
is($job->id, $id);
is($job->status, 'completed');
ok($job->log_file, "Found log file " . $job->log_file);
like $job->log_file, qr/\.log$/;
{
    my %out = $job->logs_from_offset(4);
    like $out{logs}, qr{\Atesting_high} or die Dumper(\%out);
    ok($out{offset});
    my $data = $job->as_hashref(offset => 4);
    ok $data->{offset};
    like $data->{logs}, qr{\Atesting_high} or die Dumper($data);
}
{
    my %out = $job->logs_from_offset(0);
    like $out{logs}, qr{\AJob testing_high};
    ok($out{offset});
}
{
    my %out = $job->logs_from_offset;
    like $out{logs}, qr{\AJob testing_high};
    ok(!exists $out{offset});
}


is_deeply(from_json($job->payload), { this  => 0, test => 'òć' });

my $json = $job->as_json;
ok($json);

my $struct = from_json($json);

is_deeply($struct->{payload},  { this  => 0, test => 'òć' });
is $struct->{task}, 'testing_high';
is $struct->{status}, 'completed';
is $struct->{site_id}, '0blog0';
is $struct->{priority}, 5;
is $struct->{id}, $id;

# print Dumper($struct);

my $low_id = $othersite->jobs->enqueue(testing => { this => 1, test => 1  });

# empty the jobs

my $low_priority =  $low_id->as_hashref;

is $low_priority->{position}, 2, "At third position with base 0";

while (my $j = $site->jobs->dequeue) {
    diag "Got stale job " . $j->id;
    $j->dispatch_job;
}

is ($othersite->jobs->pending->first->as_hashref->{position}, 0);

ok($othersite->jobs->dequeue->dispatch_job);

my @jobs = $schema->resultset('Job')->pending;
ok(!@jobs, "No more pending jobs");

my $oldmode = $site->mode;
my $oldlocale = $site->locale;

$site->update({
               mode => 'openwiki',
               locale => 'en',
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/human');
$mech->submit_form(
                   with_fields => {
                                   __auth_human => 'January',
                                  },
                  );
$mech->get_ok('/random');
ok($mech->follow_link(url_regex => qr{/bookbuilder/add/.+}));
$mech->get_ok('/bookbuilder');
$mech->form_with_fields('signature_2up');
$mech->field(title => 'test');
fill_queue($site);
$mech->click;
is $mech->response->base->path, '/bookbuilder', "still here";
$mech->content_contains('too many jobs pending');

# try to publish something

$mech->get_ok('/action/text/new');

$mech->submit_form(with_fields => {
                                   title => 'blablabla' . int(rand(1000)),
                                   textbody => 'Hello there',
                                  },
                   button => 'go');

ok($mech->form_id('museform'));
$mech->click('commit');
$mech->content_contains('Changes saved') or diag $mech->response->content;

ok($mech->form_name('publish'));
$mech->click;
$mech->content_contains('too many jobs pending');
is $mech->response->base->path, '/publish/pending', "still on pending";

$site->update({
               mode => $oldmode,
               locale => $oldlocale
              });
empty_queue($site);


sub fill_queue {
    my $site = shift;
    for (1..50) {
        $site->jobs->enqueue(testing => { this => 1, test => 1  });
    }
}

sub empty_queue {
    my $site = shift;
    $site->jobs->pending->delete;
}
