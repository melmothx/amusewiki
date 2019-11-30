use strict;
use warnings;
use Test::More tests => 69;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use File::Spec::Functions qw/catdir/;

use File::Temp;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Log::Contextual;

unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull1';
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
                                               host => "$site_id.amusewiki.org");

$mech->get('/console/git');
is $mech->status, 401, "Denied access to not logged in";
$mech->content_lacks('__auth_human');
$mech->content_contains('__auth_pass');

$mech->get('/console/unpublished');
is $mech->status, 401, "Denied access to not logged in";
$mech->content_lacks('__auth_human');
$mech->content_contains('__auth_pass');

# create an unpublished text.

my ($rev) = $site->create_new_text({ uri => 'deleted-text', title => 'Deleted',
                                     lang => 'en' }, 'text');

$rev->edit("#title Deleted\n#DELETED garbage\n\nblablab\n");
$rev->commit_version;
ok $rev->publish_text;

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => "$site_id.amusewiki.org");

$mech->get('/console/unpublished');
is $mech->status, 401;
ok($mech->form_id('login-form'), "Found the login-form");

$mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root'});
$mech->content_contains('You are logged in now!');

$mech->get('/console/unpublished?__language=en');

$mech->content_contains('/library/deleted-text');

$mech->content_contains(q{/action/text/edit/deleted-text"});

ok($mech->follow_link( text_regex => qr/deleted-text$/),
   "Following link to deleted-text");

like $mech->uri->path, qr{action/text/edit/deleted-text/[0-9]+$},
  "Got the editing";
$mech->content_contains('Editing deleted-text');
$mech->content_contains('#DELETED garbage');

my $orig_hashref = $site->remote_gits_hashref;
# diag Dumper($orig_hashref);
foreach my $proto ('https', 'http', 'git') {
    my $path = '/git/amusewiki.git';
    my $url = $path;
    if ($proto) {
        $url = "$proto://localhost.localdomain.tld" . $path;
    }
    my $name = "testremote" . $proto;
    ok(!$site->add_git_remote($name, "git\@localhost:/$path"), "SSH thing not added $name git\@localhost:/$path");
    ok(!$site->add_git_remote($name, $path), "Local path not allowed");
    ok(!$site->add_git_remote("$name $name", $url), "Invalid name not added");
    ok(!$site->add_git_remote($name, $url . ' ' . $url), "Invalid url not added");
    ok($site->add_git_remote($name, $url), "Added $url $name");
    ok($site->remote_gits_hashref->{$name}, "$name found in the hashref");
    ok($site->remove_git_remote($name), "Removed $name");
}

is_deeply $site->remote_gits_hashref, $orig_hashref;

ok(!$site->remove_git_remote('origin'), "Removing origin not allowed, it's local");

foreach my $remote (keys %{$site->remote_gits_hashref}) {
    diag "Removed $remote";
    $site->git->remote(rm => $remote);
}

ok !scalar(keys %{$site->remote_gits_hashref}), "Remote cleaned";


$mech->get_ok('/console/git');
ok($mech->submit_form(with_fields => {name => 'root', url => 'https://amusewiki.org/var/git/pippo.git' }), "Added root");
ok($site->remote_gits_hashref->{root}, "remote exists");
ok($mech->submit_form(form_name => "git-delete"), "Removed root via GUI");
ok(!$site->remote_gits_hashref->{root}, "root removed");

ok($mech->submit_form(with_fields => {name => 'pippo', url => 'https://amusewiki.org/var/git/pippo.git' }), "Added pippo");
ok(!$site->remote_gits_hashref->{pippo}, "remote pippo is not created");

$mech->get_ok('/console/git');
ok($mech->content_lacks('git-delete'));
ok($mech->submit_form(with_fields => {name => 'pippo-ciao', url => 'https://amusewiki.org/var/git/pippo.git' }), "Added pippo");
ok(!$site->remote_gits_hashref->{pippo}, "faulty name");

$mech->get_ok('/console/git');
ok($mech->content_lacks('git-delete'));
ok($mech->submit_form(with_fields => {name => 'root', url => 'git@amusewiki.org/var/git/pippo.git' }), "Added root fails");
ok(!$site->remote_gits_hashref->{root}, "faulty url");

$mech->get_ok('/console/git');
ok($mech->content_lacks('git-delete'));
ok($mech->submit_form(with_fields => {name => 'root', url => '/etc' }), "Added root fails");
ok(!$site->remote_gits_hashref->{root}, "no path allowed");


