#!/usr/bin/env perl

# test which always passes, but which has the site effect to bootstrap
# the archives needed for the tests. TODO Activate this properly
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree/;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;

if ($ENV{RELEASE_TESTING}) {
    plan tests => 10;
}
else {
    plan skip_all => "Skipping bootstrapping";
    exit;
}


if (-f 'test.db') {
    unlink 'test.db' or die $!;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');

$schema->deploy;

ok (-f 'test.db', "test.db created");
ok($schema, "Schema exists now");

# we create two repos, 0blog0 and 0test0

# create the root user

my $mr_root = $schema->resultset('User')
  ->create({
            username => 'root',
            password => 'root',
           })->get_from_storage;

my $root_role = $schema->resultset('Role')->create({ role => 'root' });
my $libr_role = $schema->resultset('Role')->create({ role => 'librarian' });

$mr_root->add_to_roles($root_role);

ok($mr_root->id);

my %repos = ('0blog0' => {
                          id => '0blog0',
                          locale => 'hr',
                          mode => 'modwiki',
                          sitename => 'A moderated wiki',
                          siteslogan => 'samo test',
                          bb_page_limit => 5,
                          logo => 'logo-yu',
                          canonical => 'http://blog.amusewiki.org',
                          a4_pdf => 0,
                          lt_pdf => 0,
                          papersize => 'a4',
                          division => '9',
                          bcor => '1cm',
                          fontsize => 12,
                          mainfont => 'Charis SIL',
                          twoside => 1,
                          vhosts => [{ name => 'blog.amusewiki.org' }],
                         },
             '0test0' => {
                          id => '0test0',
                          locale => 'en',
                          mode => 'blog',
                          sitename => 'A test blog',
                          siteslogan => 'only a test',
                          theme => 'test-theme',
                          bb_page_limit => 10,
                          logo => 'logo-en',
                          canonical => 'http://test.amusewiki.org',
                          a4_pdf => 0,
                          pdf => 1,
                          lt_pdf => 0,
                          papersize => '',
                          division => '12',
                          bcor => '0mm',
                          fontsize => 10,
                          mainfont => '',
                          twoside => 1,
                          vhosts => [{ name => 'test.amusewiki.org' }],
                         },
            );

foreach my $repo (sort keys %repos) {
    my $src = catdir(qw/t test-repos/, $repo);
    my $dest = catdir('repo', $repo);
    if (-d $dest) {
        remove_tree($dest) or die $!;
    }
    ok(dircopy($src, $dest), "File copied, ready to go");
    my $site = $schema->resultset('Site')->create($repos{$repo})->get_from_storage;
    ok ($site->id) or diag $repo->{id} . " couldn't be created";
    $site->magic_question('First month of the year');
    $site->magic_answer('January');
    $site->sitegroup('1');
    $site->update;
    $site->update_db_from_tree;
}

my $blog = $schema->resultset('Site')->find('0blog0');

foreach my $i (1..3) {
    my $user = $schema->resultset('User')
      ->create({
                username => "user" . $i,
                password => "pass",
               })->get_from_storage;
    if ($i == 3) {
        $user->active(0);
        $user->update;
    }
    $user->add_to_roles($libr_role);
    $user->add_to_sites($blog);
    ok($user->id, "Found " . $user->id);
}
