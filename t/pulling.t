#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 53;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;

use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });
my $git = $site->git;

ok ((-d $site->repo_root), "test site created");

my $testdir = File::Temp->newdir(CLEANUP => 1);
my $remotedir = $testdir->dirname;
ok( -d $remotedir, "Found $remotedir");

my $remote = Git::Wrapper->new($remotedir);

$remote->init({ bare => 1 });

$git->remote(add => origin => $remotedir);


my @remotes = $site->remote_gits;
is_deeply(\@remotes, [
                      {
                       name => 'origin',
                       url => $remotedir,
                       action => 'fetch',
                      },
                      {
                       name => 'origin',
                       url => $remotedir,
                       action => 'push',
                      }

                     ], "Found remotes") or diag Dumper(\@remotes);


is_deeply $site->remote_gits_hashref, {
                                       origin => {
                                                  fetch => $remotedir,
                                                  push  => $remotedir,
                                                 },
                                      }, "Found remotes hashref";

$site->repo_git_push;


my ($rlog) = $remote->log;
my ($llog) = $site->git->log;

ok($rlog, "Found log in remote");
ok($llog, "Found log in local");
is ($rlog->message, $llog->message, "Pushing worked: " . $rlog->message);

my $working_copy_dir_obj = File::Temp->newdir;
my $working_copy_dir = $working_copy_dir_obj->dirname;
my $working_copy = Git::Wrapper->new($working_copy_dir);

$working_copy->init;
$working_copy->remote(add => origin => $remotedir);
$working_copy->pull(qw/origin master/);
my ($wlog) = $working_copy->log;
is ($wlog->message, $rlog->message, "Pulling worked: " . $rlog->message);

diag "Adding a file and pushing";

make_path(catdir($working_copy_dir, qw/a at/));
my $newfile = catfile($working_copy_dir, qw/a at a-test.muse/);

copy(catfile(qw/t files shot.png/),
     catfile($working_copy_dir, qw/a at a-t-pdf.png/)) or die;

copy(catfile(qw/t files shot.png/),
     catfile($working_copy_dir, qw/a at a-t-pdfx.png/)) or die;


write_file($newfile,
           "#title A Test\n#author Pippo\n\nblabla bla\n");

ok (-f $newfile, "$newfile written");
$working_copy->add($newfile);
$working_copy->add(catfile($working_copy_dir, qw/a at a-t-pdf.png/));
$working_copy->add(catfile($working_copy_dir, qw/a at a-t-pdfx.png/));
$working_copy->commit({ message => "Work at home" });
$working_copy->push(qw/origin master/);

($rlog) = $remote->log;

is $rlog->message, "Work at home\n", "Pushing ok";

$site->repo_git_pull;
$site->update_db_from_tree;
ok(-f catfile($site->repo_root, qw/a at a-test.zip/), "Found zip");
ok(-f catfile($site->repo_root, qw/a at a-test.html/), "Found html");
ok(-f catfile($site->repo_root, qw/a at a-test.tex/), "Found html");
ok(-f catfile($site->repo_root, qw/a at a-test.bare.html/), "Found bare html");
ok(-f catfile($site->repo_root, qw/a at a-t-pdf.png/), "Found png");
ok(-f catfile($site->repo_root, qw/a at a-t-pdfx.png/), "Found png");

my ($gitlog) = $site->git->log;

is $gitlog->message, "Work at home\n", "Pulling in site ok";

my $title = $site->titles->text_by_uri('a-test');
ok ($site->attachments->by_uri('a-t-pdf.png'), "Found attachment");
ok ($site->attachments->by_uri('a-t-pdfx.png'), "Found second attachment");
is ($title->title, "A Test", "Find title in db");
my $author = $title->authors->first;

is ($author->name, 'Pippo', "Found author in db");

my $current_size = -s catfile($site->repo_root, qw/a at a-test.muse/);
write_file($newfile,
           "#title A Test\n#author Pippo\n\nblabla bla\n\nFirst file\n\n");

my $secondfile = catfile($working_copy_dir, qw/a at a-test-2.muse/);

write_file($secondfile,
           "#title A Test 2\n#author Pippo\n\nblabla bla\nSecond File\n");


$working_copy->add($newfile);
$working_copy->add($secondfile);
$working_copy->commit({ message => "Second commit, two files" });
$working_copy->push(qw/origin master/);

$site->repo_git_pull;
$site->update_db_from_tree;
ok($current_size != (-s catfile($site->repo_root, qw/a at a-test.muse/)));

foreach my $f (qw/a-test a-test-2/) {
    ok(-f catfile($site->repo_root, qw/a at/, "$f.zip"), "Found zip");
    ok(-f catfile($site->repo_root, qw/a at/, "$f.html"), "Found html");
    ok(-f catfile($site->repo_root, qw/a at/, "$f.tex"), "Found html");
    ok(-f catfile($site->repo_root, qw/a at/, "$f.bare.html"), "Found bare html");
    my $path = catfile($site->repo_root, qw/a at/, "$f.muse");
    my $title = $site->find_file_by_path($path);
    ok $title, "Found the title";
    ok $title->title, "Found the title " . $title->title;
    like $title->html_body, qr/blabla/;
}

$working_copy->rm($secondfile);
my $another_file = catfile($working_copy_dir, qw/a at a-test-3.muse/);
write_file($another_file,
           "#title A Test 3\n#author Pippox\n\nblabla bla\nSecond Filex\n");
write_file($newfile,
           "#title A Test\n#author Pippo\n\nblabla bla\nSecond File\nAppended\n");
$working_copy->add($another_file);
$working_copy->add($newfile);
my $binary = catfile($working_copy_dir, qw/a at a-t-cover.png/);
copy catfile(qw/t files shot.png/), $binary;
$working_copy->add($binary);
$working_copy->commit({ message => "Removed second file" });
$working_copy->push(qw/origin master/);

$site->repo_git_pull;

is $site->jobs->count, 1;
my $bulk = $site->update_db_from_tree_async;
is $bulk->task, 'reindex';
ok $bulk->is_reindex;
is $site->jobs->count, 4, "4 jobs found";
diag $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
while (my $job = $site->jobs->dequeue) {
    if ($job->task eq 'build_static_indexes') {
        $job->dispatch_job;
        next;
    }
    my $uri = $job->dispatch_job->produced;
    $job->delete;
    ok $uri, "Got uri: $uri";
    $mech->get_ok($uri);
}

my $removed = catfile($site->repo_root, qw/a at/, "a-test-2.muse");
ok (! -f catfile($site->repo_root, qw/a at/, "a-test-2.muse"), "File deleted");
ok (! $site->find_file_by_path($removed));
ok (! $site->titles->find({ uri => "a-test-2" }), "$removed purged in the db");
ok ($site->find_file_by_path(catfile(qw/a at/, "a-test-3.muse")), "Found $another_file in the db");
ok ($site->titles->find({ uri => "a-test" }), "Found text in the db");
ok ($site->titles->find({ uri => "a-test-3" }), "Found new text in the db");
