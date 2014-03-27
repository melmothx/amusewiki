#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 46;
use File::Slurp qw/read_file/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Edit;

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

ok (! -f $revision->starting_file, "No orig.muse");
$revision->edit("blablabla");
is $revision->muse_body, "blablabla", "Body overwritten";
ok (-f $revision->starting_file, "Found orig.muse");
like $revision->starting_file, qr/orig\.muse$/,
  "orig file looks good " . $revision->starting_file;

# is $revision->status, 'editing';

$revision->edit("blablablaasdfasdf\r\nlaksdf\r\n");

unlike $revision->muse_body, qr/\r/, "Carriage return stripped";
is $revision->muse_body, "blablablaasdfasdf\nlaksdf\n";

# clean up for next test iteration
$revision->title->delete;

