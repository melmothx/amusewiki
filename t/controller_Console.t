use strict;
use warnings;
use Test::More tests => 9;
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

