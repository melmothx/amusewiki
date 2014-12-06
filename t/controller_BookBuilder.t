use strict;
use warnings;
use Test::More tests => 57;
use File::Spec;
use Data::Dumper;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
my $orig_locale = $site->locale;
# set it to english for testing purposes.
$site->locale('en');
$site->update;

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


$mech->get_ok('/bookbuilder/');


$mech->get_ok('/bookbuilder/add/alsdflasdf');

$mech->content_contains("test if the user is a human");

$mech->form_with_fields('answer');
$mech->field(answer => 'January');
$mech->click;
is ($mech->status, '404', "bogus text not found: " . $mech->status);
is $mech->uri->path, '/library/alsdflasdf';
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");


$mech->get('/bookbuilder/add/alsdflasdf');

is ($mech->status, '404', "bogus text not found: " . $mech->status);
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");

$mech->get_ok('/library/second-test');

# 5 times
foreach my $i (1..5) {
    $mech->get_ok('/bookbuilder/add/second-test');
    is ($mech->uri->path, '/library/second-test');
    $mech->content_contains('The text was added to the bookbuilder');
    $mech->get('/bookbuilder');
    $mech->content_lacks("Couldn't add the text");
    $mech->content_lacks("Quota exceeded");
    $mech->content_contains("Total pages: $i");
}

$mech->get_ok('/bookbuilder/add/second-test');
$mech->content_contains("Quota exceeded, too many pages");
$mech->get_ok('/bookbuilder');
$mech->content_contains('second-test');
$mech->get_ok('/bookbuilder/add/first-test');
$mech->content_contains("Quota exceeded");
$mech->get_ok('/bookbuilder');
$mech->content_lacks('first-test');
$mech->content_contains("Total pages: 5");

$mech->get('/bookbuilder/cover');
is ($mech->status, '404');
$mech->get('/bookbuilder');

foreach my $cover (qw/shot.jpg shot.png/) {
    my $coverfile = File::Spec->catfile(qw/t files/, $cover);
    my $res = $mech->submit_form(with_fields => {
                                                 coverimage => $coverfile,
                                                },
                                 button => 'update',
                                );

    $mech->content_contains('coverfile-is-present');
    $mech->get_ok('/bookbuilder/cover');
    $mech->get_ok('/bookbuilder');
}

$site->locale($orig_locale);
$site->update->discard_changes;

diag "Locale restored to " . $site->locale;
