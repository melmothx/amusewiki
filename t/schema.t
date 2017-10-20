#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use Cwd;
use File::Spec;

use AmuseWikiFarm::Schema;

my $db = AmuseWikiFarm::Schema->connect('amuse');

ok($db);

my $site = $db->resultset('Site')->find('0test0');

ok($site);

my $test = $site->titles->random_text;

like $test->html_body, qr/<p>/, "Found the HTML body"
  or diag $test->title . " without a body?";
like $test->muse_body, qr/#title/, "Found the muse body";

is ($site->repo_root, File::Spec->catdir(getcwd(), repo => $site->id));

my $targetdir = $site->path_for_file("che-cacca");

is ($targetdir, File::Spec->catdir($site->repo_root,
                                   qw/c cc/));

diag "Found $targetdir";
rmdir $targetdir if -d $targetdir;
ok (-d $site->path_for_file("che-cacca"));

is ($site->mode, 'blog');

$site = $db->resultset('Site')->find('0blog0');

is $site->repo_root_rel, File::Spec->catdir('repo', '0blog0');
is $site->repo_root, File::Spec->catdir(getcwd(), 'repo', '0blog0');

my $tmp = File::Spec->tmpdir;

is $site->repo_root($tmp), File::Spec->catdir($tmp, qw/repo 0blog0/);

is $site->repo_root(0), File::Spec->catdir(getcwd(), 0, qw/repo 0blog0/);


my @users = $site->users->search({ username => { -like => 'user%' }});

ok ((@users == 3), "3 users named user* found");

foreach my $user (@users) {
    ok ($user->username);
    ok ($user->password);
}

my $user = $db->resultset('User')->find({ username => 'root' });

my $usite = $user->sites->find({ id => '0blog0' });
ok (!$usite);
