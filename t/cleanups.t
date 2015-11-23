#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use strict;
use warnings;
use Test::More tests => 28;
use DateTime;
use Cwd;
use File::Spec::Functions qw/catfile/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::BookBuilder;
use Data::Dumper;

my $init = catfile(getcwd(), qw/script jobber.pl/);
# kill the jobber
ok(system($init, 'stop') == 0) or die "Couldn't stop the jobber";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
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
my $should_remove = $bb->coverfile;
ok($should_remove, "Coverfile is $should_remove");
ok(-f $should_remove, "Coverfile $should_remove exists");
$bb->add_file($cover);
ok(! -f $should_remove, "Old coverfile now is gone");
isnt $bb->coverfile, $should_remove;

isnt $bb->coverfile, $cover, "Cover saved into " . $bb->coverfile;
is_deeply ($bb->texts, [@uris, @uris], "Texts imported");
# ok, we're settled

diag Dumper($bb->serialize);

# enqueue the job
my $job = $site->jobs->bookbuilder_add($bb->serialize);

# dispatch
$job->dispatch_job;

is ($job->bookbuilder->as_job->{template_options}->{cover}, $bb->coverfile,
  "cover can be retrieved");

my @leftovers = $job->produced_files;
is (scalar(@leftovers), 4, "Found 4 files to nuke");
diag "Leftovers: " . Dumper(\@leftovers);
foreach my $file (@leftovers) {
    ok (-f $file, "$file exists");
}

$job->delete;
foreach my $file (@leftovers) {
    ok (! -f $file, "$file deleted as expected");
}

$bb->add_file($cover);
$job = $site->jobs->bookbuilder_add($bb->serialize);
diag "Unlinking " . $bb->coverfile . " before dispatching";
unlink $bb->coverfile or die $!;
$job->dispatch_job;
diag $job->produced;
is $job->status, 'completed', "Even if the cover is missing, the thing went ok";
$job->delete;

$job = $site->jobs->alias_create_add({ src => 'pippo',
                                       dest => 'pluto',
                                       type => 'type' });

$job->dispatch_job;

@leftovers = $job->produced_files;
is (scalar(@leftovers), 1, "Found 1 file to nuke");
diag "Leftovers: " . Dumper(\@leftovers);
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
diag Dumper($bb->serialize);
$job = $site->jobs->bookbuilder_add($bb->serialize);
diag "job is is " . $job->id;
my $check = $site->jobs->find($job->id);
$check->dispatch_job;
$check = $site->jobs->find($job->id);
ok ($check, "Job retrieved");
my $expected = catfile(qw/root custom/, $job->id . '.epub');
ok (-f $expected, "EPUB created");
$check->delete;
ok (! -f $expected, "EPUB cleaned up after record removal");



