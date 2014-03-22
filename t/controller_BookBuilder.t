use strict;
use warnings;
use Test::More tests => 30;


use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


$mech->get_ok('/bookbuilder/');


$mech->get_ok('/bookbuilder/add?text=alsdflasdf');
$mech->content_contains("Couldn't add the text");

# 5 times
foreach my $i (1..5) {
    $mech->get_ok('/bookbuilder/add?text=second-test');
    $mech->content_lacks("Couldn't add the text");
    $mech->content_lacks("Quota exceeded");
    $mech->content_contains("Total pages: $i");
}

$mech->get_ok('/bookbuilder/add?text=second-test');
$mech->content_contains("Quota exceeded");
$mech->content_contains('second-test');
$mech->get_ok('/bookbuilder/add?text=first-test');
$mech->content_contains("Quota exceeded");
$mech->content_lacks('first-test');
$mech->content_contains("Total pages: 5");
