use strict;
use warnings;
use Test::More tests => 49;


use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


$mech->get_ok('/bookbuilder/');


$mech->get_ok('/bookbuilder/add?text=alsdflasdf');

$mech->content_contains("test if the user is a human");

$mech->form_with_fields('answer');
$mech->field(answer => 'January');
$mech->click;
is ($mech->status, '404', "bogus text not found: " . $mech->status);
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");


$mech->get('/bookbuilder/add?text=alsdflasdf');

is ($mech->status, '404', "bogus text not found: " . $mech->status);
$mech->content_contains("Couldn't add the text");
$mech->content_contains("Page not found!");

$mech->get_ok('/library/second-test');

# 5 times
foreach my $i (1..5) {
    $mech->get_ok('/bookbuilder/add?text=second-test');
    is ($mech->uri->path, '/library/second-test');
    $mech->content_contains('The text was added to the bookbuilder');
    $mech->get('/bookbuilder');
    $mech->content_lacks("Couldn't add the text");
    $mech->content_lacks("Quota exceeded");
    $mech->content_contains("Total pages: $i");
}

$mech->get_ok('/bookbuilder/add?text=second-test');
$mech->content_contains("Quota exceeded, too many pages");
$mech->get_ok('/bookbuilder');
$mech->content_contains('second-test');
$mech->get_ok('/bookbuilder/add?text=first-test');
$mech->content_contains("Quota exceeded");
$mech->get_ok('/bookbuilder');
$mech->content_lacks('first-test');
$mech->content_contains("Total pages: 5");
