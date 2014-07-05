#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 36;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use File::Basename qw/basename/;
use File::Temp;
use Data::Dumper;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my @source_files = map { catfile(qw/t files/, $_) } qw/shot.jpg shot.png shot.pdf/;

print Dumper(\@source_files);

my $tmpdir = File::Temp->newdir;

my @attach;
foreach my $f (@source_files) {
    die "Missing test file $f" unless -f $f;
    my $target = catfile($tmpdir->dirname, basename($f));
    copy ($f, $tmpdir->dirname) or die $!;
    push @attach, $target;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0fizl0');

my $suffix = 1;
test_revision($site, text => $suffix);
$suffix++;
test_revision($site, special => $suffix);


sub test_revision {
    my ($site, $class, $suffix) = @_;
    my $outpath = $class eq 'special' ? '/special/' : '/library/';
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         lang => 'hr',
                                         textbody => '<p>ciao</p>'
                                       }, $class);
    ok ($rev, "Revision exists");
    is $rev->f_class, $class, "Revision has $class";
    $rev->commit_version;
    is $rev->publish_text, $outpath . 'hello';
    # reset
    $rev->discard_changes;
    # check the path
    my $expected;
    if ($class eq 'special') {
        $expected = catfile($site->repo_root, qw/specials hello.muse/);
    }
    else {
        $expected = catfile($site->repo_root, qw/h ho hello.muse/);
    }
    ok (-f $expected, "$expected exists");
    like $rev->title->f_full_path_name, qr/\Q$expected\E/, "$expected ok in db";
    $rev = $rev->title->new_revision;
    # upload the files
    foreach my $att (@attach) {
        is $rev->add_attachment($att), 0, "$att uploaded";
    }
    $rev->commit_version;
    is $rev->publish_text, $outpath . 'hello';

    my $imagepath;
    if ($class eq 'special') {
        $imagepath = catdir($site->repo_root, 'specials');
    }
    else {
        $imagepath = catdir($site->repo_root, qw/h ho/);
    }
    my @files;
    foreach my $ext (qw/jpg png/) {
        my $expim = catfile($imagepath, "h-o-hello-$suffix.$ext");
        ok (-f $expim, "$expim exists");
        push @files, $expim;
    }
    my $pdf = catfile($site->repo_root, uploads => "h-o-hello-$suffix.pdf");
    ok (-f $pdf, "pdf $pdf exists");
    push @files,$pdf;

    my $git = $site->git;
    foreach my $f (@files) {
        my $attdb = $site->attachments->find({ f_full_path_name => $f });
        ok ($attdb, "record found");
        my @logs = $git->log($f);
        ok (@logs) and diag "$f => " . $logs[0]->id;
    }
}
