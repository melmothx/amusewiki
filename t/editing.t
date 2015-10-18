#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 99;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/read_file write_file/;
use File::Spec;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use File::Copy;
use File::Path qw/make_path/;

use lib File::Spec->catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0editing0');

my $existing_path = File::Spec->catdir($site->repo_root, qw/d dt/);
my $existing = File::Spec->catfile($existing_path, 'deleted-text.muse');

make_path($existing_path) or die $!;

write_file($existing, "#title deleted\n#DELETED test\n\nblaksldfal");

$site->index_file($existing);


# get the params
                                             

my $params = {};
my ($revision, $error) = $site->create_new_text($params, 'text');

ok(!$params->{uri});
ok($error, "Found error: " . $error);

$params = { author => 'pInco ', title => ' Pallino ' };
($revision, $error) = $site->create_new_text($params, 'text');

is $params->{uri}, 'pinco-pallino', "Found uri pinco-pallino";
ok !$error, "No error";
ok $revision->id, "Found revision " . $revision->id;
ok -f ($revision->f_full_path_name),
  "Text stored in " . $revision->f_full_path_name;

my $muse = $revision->muse_body;

like $muse, qr/^#author pInco$/m, "Found author";
is $revision->muse_header->{author}, 'pInco', "author found in the header";
is $revision->muse_header->{title}, 'Pallino', "title found in the header";
ok $revision->muse_header->{pubdate}, "found the pubdate"
  and diag "Revision has pubdate: " . $revision->muse_header->{pubdate};
like $muse, qr/^#title Pallino$/m, "Found title";
ok !$revision->is_deferred, "text is not deferred";
is $revision->deferred_pubdate, '', "no deferred pubdate";
$revision->edit("#title test\n#pubdate 2026-10-11 12:00\n\nBlabla");
is $revision->is_deferred, "2026-10-11", "text now is deferred";
is $revision->muse_header->{pubdate}, "2026-10-11 12:00";
$revision->edit("garbage");
ok !$revision->is_deferred, "text is not deferred";
$revision->edit("#pubdate lkasdlfkjalsdf\n\nblabla");
ok !$revision->is_deferred, "text is not deferred";
$revision->edit($muse);
ok !$revision->is_deferred, "text is not deferred";

$revision->title->delete;

$params = { author => 'DeLeTeD ', title => ' TeXt- ' };
($revision, $error) = $site->create_new_text($params, 'text');
ok(!$revision, "Nothing returned");
ok $error, "Found an error";

# clean up before testing

if (my $testtext = $site->titles->find({ uri => 'my-uri-eruerer' })) {
    $testtext->delete;
}

$params = {
           LISTtitle => "subtitle",
           SORTauthors => "first author",
           SORTtopics => "topic1, topic2",
           author => "author",
           date => "2014",
           go => "Prepare this text for the archiving",
           lang => "hr",
           textbody => "<p>Hello <em>world <s>sdafasdf asdfasd asdf asdf</s></em> asdf <strong>asdf </strong></p>\r",
           notes => "<p>Hello there asd\n<strong>fasdf</strong> as df</p>",
           source => "the source",
           subtitle => "subtitle",
           title  => "title",
           uri  => "my-uri-  eruerer ",
          };

# copy
my %check = %$params;

($revision, $error) = $site->create_new_text($params, 'text');
ok (-d $site->staging_dirname, "Found and created the staging dir");
ok $revision, "Revision created";

is $params->{uri}, 'my-uri-eruerer', "URI generated";

ok !$error, "No error set";
ok $revision->id, "Found revision" . $revision->id;
ok (-d $revision->working_dir, "Working dir exists: " . $revision->working_dir);

$muse = $revision->muse_body;

foreach my $k (qw/title
                  subtitle
                  LISTtitle
                  author
                  SORTauthors
                  SORTtopics
                  source
                  date
                  lang/) {
    my $string = $check{$k};
    ok $string, "parameter $k was passed as $string";
    like $muse, qr/\Q$string\E/, "And found in the body";
}

my $html_stored = read_file($revision->original_html);
is $html_stored, $params->{textbody} . "\n", "HTML saved verbatim with new line";

like $muse, qr/^#notes Hello there asd <strong>fasdf<\/strong> as df$/m,
  "Notes parsed correctly";
like $muse, qr/Hello <em>world/, "Body seems fine";

ok (-f $revision->starting_file, "Original body was stored");
$revision->edit("blablaàbla");
is $revision->muse_body, "blablaàbla\n", "Body overwritten, but new line appended";
ok (-f $revision->starting_file, "Found orig.muse");
like $revision->starting_file, qr/orig\.muse$/,
  "orig file looks good " . $revision->starting_file;

# is $revision->status, 'editing';

$revision->edit("blablablaasdfasdf\r\nlaksdf\r\n");

is $revision->muse_body, "blablablaasdfasdf\nlaksdf\n";

unlike $revision->muse_body, qr/\r/, "Carriage return stripped";

$revision->edit({fix_links => 1,
                 fix_typography => 1,
                 body => qq{#title bla\n#lang en\n\n"hello"\n"there"}});

is $revision->muse_body, qq{#title bla\n#lang en\n\n“hello”\n“there”\n};

$revision->edit("#title From editing\n\n llaksdl ajksdflja lsdjkfl akjsdf\n");


foreach my $att (qw/png jpg pdf/) {
    my $attachment = File::Spec->catfile(t => files => 'shot.' . $att);
    ok (-f $attachment);
    # make a copy without extension
    my $obfuscated = File::Spec->catfile(t => files => 'xx' . $att . 'grbgd');
    copy ($attachment, $obfuscated);
    ok (-f $obfuscated);
    is $revision->add_attachment($obfuscated), undef, "Attachment successful";
    unlink $obfuscated;
}

my @attached = @{ $revision->attached_files };

ok ((@attached == 3), "Got 3 attachment " . Dumper(\@attached));

my @attached_paths = $revision->attached_files_paths;

ok ((@attached_paths == 3), "Got 3 path " . Dumper(\@attached_paths));

my %todo = (
            jpg => 1,
            png => 1,
            pdf => 1,
           );
foreach my $f (@attached_paths) {
    ok (-f $f);
    ok (index($f, $revision->working_dir) == 0);
    if ($f =~ m/\.(\w+)$/) {
        delete $todo{$1};
    }
}
ok (!%todo, "All extensions found");

foreach my $f (@attached) {
    my $att = $site->attachments->find({ uri => $f});
    ok($att, "Attachment found in the db") and diag($att->uri);
}

# clean up for next test iteration

my %dests = $revision->destination_paths;

ok (%dests, "Found destination paths");

foreach my $k (keys %dests) {
    ok (-f $k, "Found $k => $dests{$k}");
}

ok !$revision->pending, "Revision is not pending";
ok $revision->editing, "Revision is under edit";
$revision->commit_version;
ok $revision->publish_text, "Text is published now";

ok !$revision->publish_text, "Can't publish an already published revision";







%todo = (
         jpg => 'jpg',
         png => 'png',
         pdf => 'pdf',
        );

foreach my $file (@attached_paths) {
    my $out = $dests{$file};
    ok ($out, "dest for file $file exists: $out");
    ok (-f $out);
    if ($out =~ m/\.(\w+)$/) {
        my $ext = delete $todo{$1};
        die "Already caught $ext!" unless $ext;
        diag "$file => $out => $ext";
        if ($ext eq 'pdf') {
            like $out, qr/uploads.*pdf$/;
        }
        else {
            like $out, qr/m.mu.m-u-my-uri.*\Q$ext\E$/;
        }
    }
}

ok !%todo, "all destinations are ok";


my $rev_id = $revision->id;

undef $revision;


my $testtext = $site->titles->find({ uri => 'my-uri-eruerer' });

ok $testtext->id;

ok $testtext->title, "revision has been published" and diag $testtext->title;

ok $testtext->is_published, "Published ok";

my $published_rev = $site->revisions->find($rev_id);

ok $published_rev->published, "Revision is published"
  or diag $published_rev->status;


$testtext->delete;

my $purge_rev = $site->revisions->find($rev_id);

ok(!$purge_rev, "Revision $rev_id purged");

# $revision->title->delete;

