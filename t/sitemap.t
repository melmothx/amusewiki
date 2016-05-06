#!perl

use utf8;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
$mech->get_ok('/robots.txt');
$mech->content_contains('sitemap.txt');
diag $mech->content;
$mech->get_ok('/sitemap.txt');
my @links = grep { /\w/ } split(/\n/, $mech->content);
print Dumper(\@links);
foreach my $link (@links) {
    $mech->get_ok($link);
    my $path = $mech->uri->path;
    like $link, qr{\Q$path\E$}, "$path is fine";
}

done_testing;
