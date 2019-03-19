#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 13;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0secfn0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$site->update({ secure_site => 0, pdf => 1 });
$site->check_and_update_custom_formats;
$mech->get_ok('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => "Secondary footnotes",
                  textbody => "\n");

$mech->click;

$mech->form_id('museform');

my $muse_body = <<'MUSE';
#title Secondary footnotes

Hello [1] There [1] {1}

{1} Secondary 1

[1] First     

[1] Second {1}

{1} Secondary 2 from the footnote # these  are nothing [1] {1} # this is

MUSE

$mech->field(body => $muse_body);
$mech->tick(fix_footnotes => 1);
$mech->tick(show_nbsp => 1);
$mech->click('commit');

my $expected = <<'MUSE';
#title Secondary footnotes

Hello [1] There [2] {1}

{1} Secondary 1

[1] First~~~~~~~~~~

[2] Second {2}

{2} Secondary 2 from the footnote # these  are nothing [1] {1} # this is

MUSE

is $site->revisions->first->muse_body, $expected;

my $uri = $site->revisions->first->publish_text;

$mech->get_ok($uri);

$mech->get_ok('/bookbuilder/add/' . $site->titles->first->uri);

$mech->get_ok('/bookbuilder');

ok $mech->form_id('bbform');
$mech->tick(nobold => 1);
$mech->tick(secondary_footnotes_alpha => 1);
ok $mech->click('build');

while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
}
