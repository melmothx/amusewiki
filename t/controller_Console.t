use strict;
use warnings;
use Test::More tests => 21;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use File::Spec::Functions qw/catdir/;

use File::Temp;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull0';
my $site = create_site($schema, $site_id);
my $git = $site->git;
my $testdir = File::Temp->newdir(CLEANUP => 0);
my $remotedir = $testdir->dirname;
ok( -d $remotedir, "Found $remotedir");

my $remote = Git::Wrapper->new($remotedir);
$remote->init({ bare => 1 });
$git->remote(add => origin => $remotedir);
$git->push(origin => 'master');

foreach my $r (qw/marco pippo pluto/) {
    $git->remote(add => $r => "git://localhost/$r/test.git");
    my @out;
    eval { @out = $git->pull($r, 'master') };
    my $fatal = $@;
    my $output = $fatal->error;
    ok($output, "Found $output");
    eval { @out = $git->push($r, 'master') };
    $fatal = $@;
    $output = $fatal->error;
    ok ($output, "Found $output");
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => '0pull0.amusewiki.org');

$mech->get_ok('/console/git');
is $mech->response->base->path, '/login', "Denied access to not logged in";

$mech->get_ok('/console/unpublished');
is $mech->response->base->path, '/login', "Denied access to not logged in";


# create an unpublished text.

my $rev = $site->create_new_text({ uri => 'deleted-text', title => 'Deleted',
                                   lang => 'en' }, 'text');

$rev->edit("#title Deleted\n#DELETED garbage\n\nblablab\n");
$rev->commit_version;
ok $rev->publish_text;

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => "$site_id.amusewiki.org");

$mech->get_ok('/console/unpublished');

ok($mech->form_id('login-form'), "Found the login-form");

$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;
$mech->content_contains('You are logged in now!');

$mech->content_contains('/library/deleted-text');

$mech->content_contains(q{/action/text/edit/deleted-text"});

ok($mech->follow_link( text_regex => qr/deleted-text$/),
   "Following link to deleted-text");

like $mech->uri->path, qr{action/text/edit/deleted-text/[0-9]+$},
  "Got the editing";
$mech->content_contains('Editing deleted-text');
$mech->content_contains('#DELETED garbage');





