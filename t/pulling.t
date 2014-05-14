#!perl

use strict;
use warnings;
use utf8;
use Test::More;

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

done_testing;
