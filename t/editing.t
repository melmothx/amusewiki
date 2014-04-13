#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 79;
use File::Slurp qw/read_file/;
use File::Spec;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive;
use AmuseWikiFarm::Archive::Edit;
use Data::Dumper;
use File::Copy;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');


# get the params
                                             

my $arch = AmuseWikiFarm::Archive::Edit->new(site_schema => $site);
my $params = {};
my $revision = $arch->create_new($params);

ok(!$params->{uri});
ok($arch->error, "Found error: " . $arch->error);

$arch = AmuseWikiFarm::Archive::Edit->new(site_schema => $site);
$params = { author => 'pInco ', title => ' Pallino ' };
$revision = $arch->create_new($params);

is $params->{uri}, 'pinco-pallino', "Found uri pinco-pallino";
ok !$arch->redirect, "No redirection";
ok !$arch->error, "No error";
ok $revision->id, "Found revision " . $revision->id;
ok -f ($revision->f_full_path_name),
  "Text stored in " . $revision->f_full_path_name;

my $muse = $revision->muse_body;

like $muse, qr/^#author pInco$/m, "Found author";
like $muse, qr/^#title Pallino$/m, "Found title";


$revision->title->delete;

$arch = AmuseWikiFarm::Archive::Edit->new(site_schema => $site);
$params = { author => 'DeLeTeD ', title => ' TeXt- ' };
$revision = $arch->create_new($params);
ok(!$revision, "Nothing returned");
is $arch->redirect, 'deleted-text', "Found a redirect, text exists";
is $arch->redirect, $params->{uri};

# clean up before testing

if (my $testtext = $site->titles->find({ uri => 'my-uri-eruerer' })) {
    $testtext->delete;
}


$arch = AmuseWikiFarm::Archive::Edit->new(site_schema => $site);
$params = {
           LISTtitle => "subtitle",
           SORTauthors => "first author",
           SORTtopics => "topic1, topic2",
           author => "author",
           date => "2014",
           go => "Prepare this text for the archiving",
           lang => "hr",
           textbody => "<p>Hello <em>world <s>sdafasdf asdfasd asdf asdf</s></em> asdf <strong>asdf </strong></p>",
           notes => "<p>Hello there asd\n<strong>fasdf</strong> as df</p>",
           source => "the source",
           subtitle => "subtitle",
           title  => "title",
           uri  => "my-uri-  eruerer ",
          };

# copy
my %check = %$params;

$revision = $arch->create_new($params);
ok (-d $arch->staging_dirname, "Found and created the staging dir");
ok $revision, "Revision created";

is $params->{uri}, 'my-uri-eruerer', "URI generated";

ok !$arch->error, "No error set";
ok !$arch->redirect, "No redirection";
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
is $html_stored, $params->{textbody}, "HTML saved verbatim";

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

unlike $revision->muse_body, qr/\r/, "Carriage return stripped";
is $revision->muse_body, "blablablaasdfasdf\nlaksdf\n";

$revision->edit("#title From editing\n\n llaksdl ajksdflja lsdjkfl akjsdf\n");


foreach my $att (qw/png jpg pdf/) {
    my $attachment = File::Spec->catfile(t => files => 'shot.' . $att);
    ok (-f $attachment);
    # make a copy without extension
    my $obfuscated = File::Spec->catfile(t => files => 'xx' . $att . 'grbgd');
    copy ($attachment, $obfuscated);
    ok (-f $obfuscated);
    is 0, $revision->add_attachment($obfuscated), "Attachment successful";
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

my $archive = AmuseWikiFarm::Archive->new(dbic => $schema,
                                          code => $site->id);

ok !$revision->pending, "Revision is not pending";
ok $revision->editing, "Revision is under edit";

$archive->publish_revision($revision->id);

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

