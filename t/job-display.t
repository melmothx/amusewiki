#!perl

use strict;
use warnings;
use Test::More tests => 18;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site start_jobber stop_jobber/;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;
my $site = create_site($schema, '0displayjob0');
for my $i (1..3) {
    $site->custom_formats->create({ format_name => "Format name $i"});
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get_ok('/login');
ok $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => 'title',
                  textbody => "Hello <em>there</em>\n");
$mech->click;
$mech->content_contains('Created new text') or die $mech->content;
ok $mech->form_id('museform');
$mech->click('commit');
ok($mech->form_name('publish'));
$mech->click;

check_jobber();

$mech->get_ok($site->titles->first->full_rebuild_uri);

check_jobber();

sub check_jobber {
    my $url = $mech->uri;
    if ($url =~ m{tasks/status/(\d+)}) {
        while (my $j = $site->jobs->dequeue) {
            $j->dispatch_job;
        }
    }
    else {
        die "Wrong url $url, expecting tasks/status";
    }
    $mech->get_ok($url);
    my $content = $mech->content;
    my $subjobs = 0;
    while ($content =~ m{^(.*as task number <a href="https://0displayjob0\.amusewiki\.org(/tasks/status/\d+)">#\d+</a>).*$}gm) {
        diag $1;
        my $subjob = $2;
        $mech->get_ok($subjob);
        $subjobs++;
    }
    is $subjobs, 3;
}
