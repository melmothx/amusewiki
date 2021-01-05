use strict;
use warnings;
use Test::More tests => 12;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0specials0';
my $site = create_site($schema, $site_id);


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

ok($mech);

$site->update({ multilanguage => 'hr en' });

foreach my $lang ([ 'en' => 'uid', "English with UID" ],
                  [ 'hr' => 'uid', "Croatian with UID" ],
                  [ 'en' => '', "English no UID" ],
                 ) {
    my $file = path($site->repo_root, specials => "about-" . ( $lang->[1] ? $lang->[0] : 'all' ) . ".muse");
    $file->parent->mkpath;
    $file->spew_utf8(<<"MUSE");
#title $lang->[2]
#uid $lang->[1]
#lang $lang->[0]

$lang->[2]
MUSE
}

foreach my $f ([ specials => 'index.muse'],
               [ t => tt => 'test.muse' ]) {
    my $file = path($site->repo_root, @$f);
    $file->parent->mkpath;
    $file->spew_utf8(<<"MUSE");
#title $f->[-1]
#lang en

$file
MUSE
}

$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

$mech->get_ok( '/special/index' );
$mech->content_contains('$("#amw-latest-entries-special-page").load("/latest',
                        "Found the latest entries");
$mech->get_ok('/latest');
$mech->content_contains('test.muse', "Found the latest entries");

$mech->content_contains('English no UID');
$mech->content_contains('English with UID');
$mech->content_lacks('Croatian with UID');

$mech->get_ok('/latest?__language=hr');
$mech->content_contains('English no UID');
$mech->content_contains('Croatian with UID');
$mech->content_lacks('English with UID');

