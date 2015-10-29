#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile/;
use Test::More tests => 51;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use JSON qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $init = catfile(getcwd(), qw/script jobber.pl/);
# kill the jobber
ok(system($init, 'stop') == 0);

my $othersite = $schema->resultset('Site')->find('0test0');

my $j = $site->jobs->enqueue(testing => {});

is $j->site->id, '0blog0';
is $j->username, "anonymous";
is $j->committer_username, "anonymous";
is $j->committer_name, "Anonymous";
is $j->committer_mail, "anonymous\@blog.amusewiki.org";
{
    my $jx = $site->jobs->enqueue(testing => {}, 10, "ùàà òò");
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
    $jx = $site->jobs->enqueue(testing => {}, 10, "pinco.pallino");
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

print Dumper($struct);

my $low_id = $othersite->jobs->enqueue(testing => { this => 1, test => 1  },
                                       10);

# empty the jobs

my $low_priority =  $low_id->as_hashref;

is $low_priority->{position}, 2, "At third position with base 0";

while (my $j = $site->jobs->dequeue) {
    diag "Got stale job " . $j->id;
}

is ($othersite->jobs->pending->first->as_hashref->{position}, 0);

ok($othersite->jobs->dequeue);

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
                                   answer => 'January',
                                  },
                   button => 'submit',
                  );
$mech->get_ok('/random');
$mech->submit_form(form_id => 'book-builder-add-text');
$mech->get_ok('/bookbuilder');
$mech->form_with_fields('signature');
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
$mech->content_contains('Changes committed') or diag $mech->response->content;

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
