#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use strict;
use warnings;
use Test::More tests => 47;
use DateTime;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::BookBuilder;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

my $mech = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => "blog.amusewiki.org");
my $mech_no_auth = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => "test.amusewiki.org");

ok ($site, "Found the site");

# create a bookbuilder job

# first get the titles uris

my @uris = map { $_->uri } $site->titles->published_texts;
ok (scalar(@uris), "Found " . join(" ", @uris));


my $bb = AmuseWikiFarm::Archive::BookBuilder->new;
foreach my $uri (@uris, @uris) {
    $bb->add_text($uri);
}
my $cover = catfile(qw/t files shot.jpg/);
ok( -f $cover, "Cover is here");
$bb->add_file($cover);
my $should_remove = $bb->coverfile_path;
ok($should_remove, "Coverfile is $should_remove");
ok(-f $should_remove, "Coverfile $should_remove exists");
$bb->add_file($cover);
ok(! -f $should_remove, "Old coverfile now is gone");
isnt $bb->coverfile, $should_remove;

isnt $bb->coverfile, $cover, "Cover saved into " . $bb->coverfile;
is_deeply ($bb->texts, [@uris, @uris], "Texts imported");
# ok, we're settled

# diag Dumper($bb->serialize);

# enqueue the job
my $job = $site->jobs->bookbuilder_add($bb->serialize);

# dispatch
$job->dispatch_job or diag $job->logs;



is ($job->bookbuilder->as_job->{template_options}->{cover}, $bb->coverfile,
  "cover can be retrieved");

foreach my $bbfile ($job->bookbuilder->produced_files) {
    my $url = '/custom/' . $bbfile;
    $mech->get_ok($url);
    $mech_no_auth->get($url);
    is $mech_no_auth->status, '404', "same file ($url) not found on another site";
}
my @leftovers = $job->produced_files;
is (scalar(@leftovers), 4, "Found 4 files to nuke");
# diag "Leftovers: " . Dumper(\@leftovers);
foreach my $file (@leftovers) {
    ok (-f $file, "$file exists");
}

$job->delete;
foreach my $file (@leftovers) {
    ok (! -f $file, "$file deleted as expected");
}

$bb->add_file($cover);
$job = $site->jobs->bookbuilder_add($bb->serialize);
diag "Unlinking " . $bb->coverfile_path . " before dispatching";
unlink $bb->coverfile_path or die $!;
$job->dispatch_job;
diag $job->produced;
is $job->status, 'completed', "Even if the cover is missing, the thing went ok";
diag $job->logs;
$job->delete;

$bb->coverfile($bb->coverfile_path);
is ($bb->coverfile, $bb->coverfile_path, "Passing an absolute filename works as well");

$job = $site->jobs->alias_create_add({ src => 'pippo',
                                       dest => 'pluto',
                                       type => 'type' });

$job->dispatch_job;

@leftovers = $job->produced_files;
is (scalar(@leftovers), 1, "Found 1 file to nuke");
# diag "Leftovers: " . Dumper(\@leftovers);
foreach my $file (@leftovers) {
    ok (-f $file, "$file exists");
}

$job->delete;
foreach my $file (@leftovers) {
    ok (! -f $file, "$file deleted as expected");
}

$bb = AmuseWikiFarm::Archive::BookBuilder->new;
$bb->import_from_params(format => 'epub');
foreach my $uri (@uris, @uris) {
    $bb->add_text($uri);
}
ok $bb->epub;
# diag Dumper($bb->serialize);
$job = $site->jobs->bookbuilder_add($bb->serialize);
diag "job id is " . $job->id;
my $check = $site->jobs->find($job->id);
$check->dispatch_job;
$check = $site->jobs->find($job->id);
my @files = $check->job_files;
ok (@files > 0, "Found the job files");

ok ($check, "Job retrieved");
my $expected = catfile(bbfiles => , $job->id . '.epub');
ok (-f $expected, "EPUB created");
$check->delete;
ok (! -f $expected, "EPUB cleaned up after record removal");

my $newjob = $site->jobs->bookbuilder_add({});
my $job_id = $newjob->id;
diag "Testing files without jobfiles $job_id";
@files = ("$job_id.pdf", "$job_id.epub", "$job_id.sl.pdf",
             "bookbuilder-$job_id.zip");

my $oldcustomdir = catdir(qw/root custom/);
mkdir $oldcustomdir unless -d $oldcustomdir;
foreach my $file (@files) {
    my $path = catfile($oldcustomdir => $file);
    open (my $fh, ">", $path) or die $!;
    print $fh "xx";
    close $fh;
}

my $upgrade_file = catfile(qw/dbicdh _common upgrade 5-6 002-add-and-move-job-files.pl/);
if (-f $upgrade_file) {
    diag "Simulating the upgrade\n";
    my $upgrade = do $upgrade_file;
    $upgrade->($schema) if $upgrade;
}

foreach my $file (@files) {
    my $url = "/custom/$file";
    $mech->get_ok($url);
    $mech_no_auth->get($url);
    is $mech_no_auth->status, '404', "same file ($url) not found on another site";
}

$newjob->delete;

foreach my $file (@files) {
    my $path = catfile(bbfiles => $file);
    ok (! -f $path, "$path deleted");
}
rmdir $oldcustomdir;
