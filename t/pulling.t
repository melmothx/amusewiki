#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 33;

use File::Path qw/make_path remove_tree/;
use File::Slurp qw/write_file/;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull0';
my $git = create_site($schema, $site_id);
my $site = $schema->resultset('Site')->find($site_id);

ok ((-d $site->repo_root), "test site created");

my $testdir = File::Temp->newdir;
my $remotedir = $testdir->dirname;
ok( -d $remotedir, "Found $remotedir");

my $remote = Git::Wrapper->new($remotedir);

$remote->init({ bare => 1 });

$git->remote(add => origin => $remotedir);

$git->push(origin => 'master');


my ($rlog) = $remote->log;
my ($llog) = $git->log;

ok($rlog, "Found log in remote");
ok($llog, "Found log in local");
is ($rlog->message, $llog->message, "Pushing worked: " . $rlog->message);
# system(qw/ls -lh/, $remotedir);

my $working_copy_dir_obj = File::Temp->newdir;
my $working_copy_dir = $working_copy_dir_obj->dirname;
my $working_copy = Git::Wrapper->new($working_copy_dir);

$working_copy->init;
$working_copy->remote(add => origin => $remotedir);
$working_copy->pull(origin => 'master');
my ($wlog) = $working_copy->log;
is ($wlog->message, $rlog->message, "Pulling worked: " . $rlog->message);

# system(qw/ls -lha/, $working_copy_dir);

diag "Adding a file and pushing";

make_path(catdir($working_copy_dir, qw/a at/));
my $newfile = catfile($working_copy_dir, qw/a at a-test.muse/);

write_file($newfile,
           { binmode => ':encoding(UTF-8)' },
           "#title A Test\n#author Pippo\n\nblabla bla\n");

ok (-f $newfile, "$newfile written");
$working_copy->add($newfile);
$working_copy->commit({ message => "Work at home" });
$working_copy->push;

($rlog) = $remote->log;

is $rlog->message, "Work at home\n", "Pushing ok";

$site->repo_git_pull;

ok(-f catfile($site->repo_root, qw/a at a-test.zip/), "Found zip");
ok(-f catfile($site->repo_root, qw/a at a-test.html/), "Found html");
ok(-f catfile($site->repo_root, qw/a at a-test.tex/), "Found html");
ok(-f catfile($site->repo_root, qw/a at a-test.bare.html/), "Found bare html");

my ($gitlog) = $git->log;

is $gitlog->message, "Work at home\n", "Pulling in site ok";

my $title = $site->titles->by_uri('a-test');
is ($title->title, "A Test", "Find title in db");
my $author = $title->authors->first;

is ($author->name, 'Pippo', "Found author in db");

my $current_size = -s catfile($site->repo_root, qw/a at a-test.muse/);
write_file($newfile,
           { binmode => ':encoding(UTF-8)' },
           "#title A Test\n#author Pippo\n\nblabla bla\n\nFirst file\n\n");

my $secondfile = catfile($working_copy_dir, qw/a at a-test-2.muse/);

write_file($secondfile,
           { binmode => ':encoding(UTF-8)' },
           "#title A Test 2\n#author Pippo\n\nblabla bla\nSecond File\n");


$working_copy->add($newfile);
$working_copy->add($secondfile);
$working_copy->commit({ message => "Second commit, two files" });
$working_copy->push;

$site->repo_git_pull;
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
$working_copy->commit({ message => "Removed second file" });

$working_copy->push;

$site->repo_git_pull;

my $removed = catfile($site->repo_root, qw/a at/, "a-test-2.muse");
ok (! -f catfile($site->repo_root, qw/a at/, "a-test-2.muse"), "File deleted");
ok (! $site->find_file_by_path($removed));
ok (! $site->titles->find({ uri => "a-test-2" }), "$removed purged in the db");
