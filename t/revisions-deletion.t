#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 48;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use File::Basename qw/basename/;
use File::Temp;
use Data::Dumper;
use DateTime;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my @source_files = map { catfile(qw/t files/, $_) } qw/shot.jpg shot.png shot.pdf/;

# print Dumper(\@source_files);

my $tmpdir = File::Temp->newdir;

my @attach;
foreach my $f (@source_files) {
    die "Missing test file $f" unless -f $f;
    my $target = catfile($tmpdir->dirname, basename($f));
    copy ($f, $tmpdir->dirname) or die $!;
    push @attach, $target;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0delrev0');

my ($rev, $error) = $site->create_new_text({
                                            title => 'prova',
                                            lang => 'en',
                                            textbody => '<p>hello</p>',
                                           }, 'text');

diag $rev->id;
ok (-d $rev->working_dir, "Found working directory: " . $rev->working_dir);

foreach my $att (@attach) {
    my $out = $rev->add_attachment($att);
    is $out->{error}, undef, "$att uploaded";
    ok $out->{attachment}, "Attachment $out->{attachment}";
}
$rev->commit_version;

my $files = ($rev->attached_files);

my @stored;

foreach my $file (@$files) {
    my $full_file = File::Spec->catfile($rev->working_dir, $file);
    ok (-f $full_file, "Found $full_file");
    push @stored, $full_file;
}

is scalar(@stored), 3, "Found 3 files";

ok $site->titles->find({ uri => 'prova' });

$rev->delete;

ok !$site->titles->find({ uri => 'prova' });


diag "After deletion...";

foreach my $file (@$files) {
    my $full_file = File::Spec->catfile($rev->working_dir, $file);
    ok (! -f  $full_file, "$full_file was removed");
    ok (!$site->attachments->find_file($full_file),
        "File not found in the db");
}

diag "New revision";

($rev, $error) = $site->create_new_text({
                                         title => 'prova',
                                         lang => 'en',
                                         textbody => '<p>hello</p>',
                                        }, 'text');

foreach my $att (@attach) {
    my $out = $rev->add_attachment($att);
    is $out->{error}, undef, "$att uploaded";
    ok $out->{attachment}, "Attachment $out->{attachment}";
}
$rev->commit_version;
$rev->publish_text;

$files = ($rev->attached_files);

$rev->delete;

foreach my $file (@$files) {
    my $full_file = File::Spec->catfile($rev->working_dir, $file);
    my $attachment_row = $site->attachments->find({ uri => $file });
    my $in_tree = $attachment_row->f_full_path_name;

    ok ($attachment_row->f_archive_rel_path,
        "File found in the db, in tree");
    ok ($full_file ne $in_tree, "Attachments moved from $full_file to $in_tree");

    ok (! -f $full_file, "$full_file was removed");
    ok (!$site->attachments->find_file($full_file),
        "File not found in the db");
}
ok (! -d $rev->working_dir, "Working directory deleted");


($rev, $error) = $site->create_new_text({
                                         title => 'prova-xxxxx',
                                         lang => 'en',
                                         textbody => '<p>hello</p>',
                                        }, 'text');
ok(!$error, "No error") or die $error;

foreach my $att (@attach) {
    my $out = $rev->add_attachment($att);
    is $out->{error}, undef, "$att uploaded";
    ok $out->{attachment}, "Attachment $out->{attachment}";
}
$rev->commit_version;
$rev->publish_text;
my $datetime = DateTime->new(year => 2002,
                             month => 1,
                             day => 2);
$rev->updated($datetime);
$rev->update;

ok !$schema->resultset('Revision')->published_older_than($datetime)->count,
  "No revisions older than $datetime";

$datetime->add(days => 1);

my $old_published_revisions =
  $schema->resultset('Revision')->published_older_than($datetime);
is $old_published_revisions->count, 1,
  "Found the revision older than $datetime";

$schema->resultset('Revision')->purge_old_revisions;

ok (! -d $rev->working_dir, "Working directory deleted") or diag $rev->working_dir;
