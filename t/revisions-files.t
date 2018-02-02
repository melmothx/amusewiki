#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 122;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use File::Basename qw/basename/;
use File::Temp;
use Data::Dumper;
use Path::Tiny;

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

my $site = create_site($schema, '0fizl0');

test_revision($site, text => 1);
# please note that here we increment just by one, because the
# extension will shift and the serie will start anew (it's the same
# base filename)
test_revision($site, special => 2);


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
        my $out = $rev->add_attachment($att);
        is $out->{error}, undef, "$att uploaded";
        ok $out->{attachment}, "Attachment $out->{attachment}";
    }

    # invalid scenario: non-existent
    my $does_not_exist = 'lasdlflasdflasd';
    is_deeply ($rev->add_attachment($does_not_exist)->{error},
               [ "[_1] doesn't exist", $does_not_exist ],
               "Error on not existing file ok");

    # and wrong mime type
    my $garbage = File::Temp->new(SUFFIX => '.txt');
    print $garbage "blabalbabla\n";
    is_deeply ($rev->add_attachment($garbage->filename)->{error},
               ["Unsupported file type [_1]", "text/plain"]);

    # print Dumper($rev->attached_images, $rev->attached_files, $rev->attached_pdfs);

    {
        my $discard = $rev->add_attachment($attach[0]);
        ok $discard->{attachment};
        ok -f path($rev->working_dir, $discard->{attachment});
        ok $site->attachments->by_uri($discard->{attachment});
        my $removal = $rev->remove_attachment($discard->{attachment});
        ok !path($rev->working_dir, $discard->{attachment})->exists, "$discard->{attachment} removed";
        ok !$site->attachments->by_uri($discard->{attachment}), "$discard->{attachment} removed from db";
        ok !$removal->{error};
        ok $removal->{success} or die;
        foreach my $fail (path($rev->working_dir)->children(qr{\.muse\z})) {
            ok -f $fail;
            diag "Testing failure on $fail";
            my $fail_uri = $fail->basename;
            my $fail_res = $rev->remove_attachment($fail_uri);
            is $fail_res->{error}, "File to delete not found!";
            ok !$fail_res->{success};
        }
        ok $rev->remove_attachment('askldfjalksdf')->{error};
    }

    my %suffixes = (
                    jpg => $suffix + 0,
                    png => $suffix + 1,
                    pdf => $suffix + 2,
                   );

    is_deeply([ sort @{$rev->attached_files} ],
              [ "h-o-hello-$suffixes{jpg}.jpg",
                "h-o-hello-$suffixes{png}.png",
                "h-o-hello-$suffixes{pdf}.pdf",
              ],
              "Attached files ok") or die;


    is_deeply([ sort @{$rev->attached_images} ],
              [ "h-o-hello-$suffixes{jpg}.jpg",
                "h-o-hello-$suffixes{png}.png",
              ],
              "Attached images ok") or die;

    is_deeply([ sort @{$rev->attached_pdfs} ],
              [ "h-o-hello-$suffixes{pdf}.pdf" ],
              "Attached pdfs ok");
    $rev->edit("#ATTACH h-o-hello-$suffixes{pdf}.pdf\n" . $rev->muse_body);
    $rev->commit_version;
    is $rev->publish_text, $outpath . 'hello';

    $rev->discard_changes;
    my $title = $rev->title;
    is ($title->attach, "h-o-hello-$suffixes{pdf}.pdf");

    my $attachment = $site->attachments->find({ uri => "h-o-hello-$suffixes{pdf}.pdf" });
    ok ($attachment, "attachment found") or die;
    is_deeply($title->attached_pdfs || [], ["h-o-hello-$suffixes{pdf}.pdf"]) or die;
    my $imagepath;
    if ($class eq 'special') {
        $imagepath = catdir($site->repo_root, 'specials');
    }
    else {
        $imagepath = catdir($site->repo_root, qw/h ho/);
    }
    my @files;
    foreach my $ext (qw/jpg png/) {
        my $expim = catfile($imagepath, "h-o-hello-$suffixes{$ext}.$ext");
        ok (-f $expim, "$expim exists");
        push @files, $expim;
    }
    my $pdf = catfile($site->repo_root, uploads => "h-o-hello-$suffixes{pdf}.pdf");
    ok (-f $pdf, "pdf $pdf exists");
    push @files,$pdf;

    my $git = $site->git;
    foreach my $f (@files) {
        my $attdb = $site->attachments->find({ f_full_path_name => $f });
        ok ($attdb, "record found");
        my @logs = $git->log($f);
        ok (@logs) and diag "$f => " . $logs[0]->id;
        if ($f =~ m/\.pdf$/) {
            ok !$attdb->can_be_inlined, "$f cannot be inlined";
        }
        else {
            ok $attdb->can_be_inlined, "$f *can* be inlined";
        }
    }
    {
        my $readd = $title->new_revision;
        foreach my $att (@attach) {
            my $got = $readd->add_attachment($att)->{attachment};
            ok $got;
            diag $got;
            ok $readd->remove_attachment($got)->{success};
            diag "Readding $got after removal";
            my $anew = $readd->add_attachment($att)->{attachment};
            ok $anew;
            isnt $got, $anew, "$got != $anew";
            ok $readd->remove_attachment($anew)->{success};
        }
    }
}
