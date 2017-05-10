#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use strict;
use warnings;
use utf8;
use Test::More tests => 6;

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Amuse;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
use Path::Tiny;
my $schema = AmuseWikiFarm::Schema->connect('amuse');


my $payload = <<'JSON';
 {"monofont":"CMU Typewriter Text","paper_width":"0","notes":"","imposed":"1","coverwidth":"100","crop_paper_thickness":"0.10mm","cover":"1","textlist":["first-test"],"fontsize":"10","crop_marks":"1","beamertheme":"default","schema":"2x4x2","coverfile":null,"bcor":"0","paper_height":"0","format":"pdf","signature":"0","beamercolortheme":"dove","date":"","source":"","notoc":null,"crop_paper_height":"0","crop_paper_width":"0","mainfont":"CMU Serif","opening":"any","division":"12","sansfont":"CMU Sans Serif","headings":"0","unbranded":null,"author":"","subtitle":"","title":"","twoside":null,"nocoverpage":null,"crop_papersize":"generic","papersize":"generic","epub_embed_fonts":"1"}
JSON

my $site = $schema->resultset('Site')->find('0blog0');

my $job = $site->jobs->bookbuilder_add(AmuseWikiFarm::Utils::Amuse::from_json($payload));
$job->dispatch_job;
my $url = $job->produced;
is $job->status, 'completed';
ok $url, "$url produced";

my $filename = $job->job_files->search({ slot => 'produced' })->first->filename;
my $file = path(bbfiles => $filename);
ok $file->exists;

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get_ok($url);
    my $old_mode = $site->mode;
    $site->update({ mode => 'private' });
    $mech->get($url);
    is $mech->status,  401;
    $site->update({ mode => $old_mode });
}
{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => 'test.amusewiki.org');
    $mech->get($url);
    is $mech->status,  404;
}
