#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 84;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0autoteaser0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0,
                pdf => 0,
                epub => 0,
                html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $attachment = catfile(qw/t files shot.png/);

my $stub = <<'MUSE';

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
minim veniam, quis nostrud exercitation ullamco laboris nisi ut
aliquip ex ea commodo consequat. Duis aute irure dolor in
reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
pariatur. Excepteur sint occaecat cupidatat non proident, sunt in
culpa qui officia deserunt mollit anim id est laborum.

MUSE

foreach my $teaser (0..1) {
    foreach my $cover (0..1) {
        foreach my $image (0..1) {
            foreach my $overflow (0..1) {
                my ($rev) = $site
                  ->create_new_text({ title => "test file cover $cover, image $image, overflow $overflow, teaser $teaser",
                                      lang => 'en',
                                      textbody => '<h2>Test</h2>',
                                    }, 'text');
                my $got = $rev->add_attachment($attachment);
                my $attcode = $got->{attachment};
                ok($attcode, "Got attachment $attcode") or die;
                my $body = $rev->muse_body;
                if ($image) {
                    $body .= "\n\n[[$attcode]]\n\n";
                }
                if ($cover) {
                    $body = "#cover $attcode\n" . $body;
                }
                if ($teaser) {
                    $body = "#teaser $teaser\n" . $body;
                }
                if ($overflow) {
                    $body = $body . ($stub x 50);
                } else {
                    $body .= $stub;
                }
                $rev->edit($body);
                $rev->commit_version;
                $rev->publish_text;
                my $title = $rev->title->discard_changes;
                $mech->get_ok($title->full_uri);
                if ($teaser) {
                    ok $title->teaser, "Teaser exists";
                }
                else {
                    ok !$title->teaser, "No teaser found";
                }
            }
        }
    }
}
$mech->get('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/user/site');
ok $mech->submit_form(with_fields => { automatic_teaser => length($stub) * 2 } ,
                      button => 'edit_site');

$site = $site->get_from_storage;

is $site->automatic_teaser, length($stub) * 2;

my $bulk = $site->rebuild_formats;
while (my $job = $site->jobs->dequeue) {
    is $job->task, 'rebuild';
    $job->dispatch_job;
    diag $job->logs;
}

foreach my $title ($site->titles) {
    ok ($title->teaser, "Found teaser") and diag $title->teaser;
}
