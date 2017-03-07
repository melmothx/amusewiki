#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 75;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy::Recursive qw/dircopy/;
use File::Copy qw/copy/;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use constant { DEBUG => 1 };

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull2';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });
my $git = $site->git;
ok ((-d $site->repo_root), "test site created");
my $testdir = File::Temp->newdir(CLEANUP => !DEBUG);
my $remotedir = $testdir->dirname;
ok( -d $remotedir, "Found $remotedir");
my $remote = Git::Wrapper->new($remotedir);
$remote->init({ bare => 1 });
$git->remote(add => origin => $remotedir);
$site->repo_git_push;
my $working_copy_dir_obj = File::Temp->newdir(CLEANUP => !DEBUG);
my $working_copy_dir = $working_copy_dir_obj->dirname;
my $working_copy = Git::Wrapper->new($working_copy_dir);
diag "Working dir is $working_copy_dir, remote is $remotedir";
$working_copy->init;
$working_copy->remote(add => origin => $remotedir);
$working_copy->pull(qw/origin master/);

# END OF SETUP

foreach my $dir (qw/specials site_files d f uploads/) {
    dircopy(catdir(qw/t test-repos 0blog0/, $dir),
            catdir($working_copy_dir, $dir));
    $working_copy->add($dir);
    $working_copy->commit({ message => "Added $dir" });
    dircopy(catdir(qw/t test-repos 0blog0/, $dir),
            catdir($working_copy_dir, 'garbage', $dir));
    $working_copy->add(catdir('garbage', $dir));
    $working_copy->commit({ message => "Added $dir under garbage" });
    $working_copy->push(qw/origin master/);
}

$site->repo_git_pull;
$site->update_db_from_tree_async(sub { diag @_ });

# now remove some files under its nose
$working_copy->rm(catfile(qw/d dt do-this-by-yourself.muse/));
$working_copy->commit({ message => "removed file" });
$working_copy->push(qw/origin master/);

$site->repo_git_pull;
$site->update_db_from_tree_async(sub { diag @_ });

while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
    if ($job->status eq 'completed') {
        my $path = $job->job_data->{path};
        diag "$path registered";
        my $thing = $site->find_file_by_path($path);
        ok($thing, "Found $path in db");
        ok $thing->full_uri;
        if ($thing->can('filepath_for_ext')) {
            foreach my $ext (qw/html tex zip/) {
                my $fpath = $thing->filepath_for_ext($ext);
                if ($thing->deleted) {
                    ok (! -f $fpath, "$fpath exists");
                }
                else {
                    ok (-f $fpath, "$fpath exists");
                }
            }
        }
    }
    elsif ($job->status eq 'failed') {
        my $path = $job->job_data->{path};
        ok $path, 'd/dt/do-this-by-yourself.muse';
        ok(!$site->find_file_by_path($path), "$path not found in db");
    }
    else {
        die "Unacceptable status " . $job->status . ' ' . $job->id;
    }
}
ok !$site->titles->texts_only->find({
                                     uri => 'do-this-by-yourself',
                                    });
my $index = $site->titles->specials_only->find({
                                                uri => 'index',
                                               });
ok -f $index->filepath_for_ext('zip');
ok $index;


my $deletion = catfile(qw/f ft first-test.muse/);
$working_copy->rm($deletion);
$working_copy->commit({ message => "removed file $deletion" });
$working_copy->push(qw/origin master/);

$site->repo_git_pull;
$site->update_db_from_tree_async(sub { diag @_ });

ok (!$site->jobs->dequeue, "no new jobs");
ok(!$site->find_file_by_path($deletion));
