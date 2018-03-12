#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 45;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my @paths = (qw[
                   authors.html 
                   titles.html topics.html site_files/navlogo.png 
                   site_files/favicon.ico
                   site_files/__static_indexes/fonts/FontAwesome.otf
              ]);

$site->update({
               cgit_integration => 0,
               mode => 'modwiki',
              });

foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}

$site->update({ cgit_integration => 1 });
ok $site->cgit_integration;

$mech->get('/robots.txt');
$mech->content_contains('http://blog.amusewiki.org/mirror.txt | wget');

foreach my $path (@paths) {
    $mech->get_ok("/mirror/$path");
}

$mech->get_ok("/mirror");
is $mech->uri->path, '/mirror/index.html';
$mech->get_ok("/mirror/");
is $mech->uri->path, '/mirror/index.html';

{
    $mech->get_ok("/mirror/index.html");
    my $index_body = $mech->content;
    $mech->get_ok("/mirror/titles.html");
    my $titles_body = $mech->content;
    is $titles_body, $index_body, "index.html and titles.html are the same";
}

foreach my $bad (qw[.git .gitignore .. . ../../../hello blaa/../hello ]) {
    $mech->get("/mirror/$bad");
    is $mech->status, 400;
}


$mech->get_ok("/mirror.txt");
$mech->content_contains('/mirror/index.html');
$mech->content_contains('/mirror/titles.html');
diag $mech->content;
my @list = grep { /\Ahttp\S*\z/ } split(/\n/, $mech->content);
my ($got_ok, $got_fail) = (0,0);
foreach my $url (@list) {
    $mech->get($url);
    $mech->status eq '200' ? $got_ok++ : $got_fail++;
}
ok ($got_ok > 30, "$got_ok requests ok");
ok (!$got_fail, "$got_fail failed request");

$mech->get_ok('/mirror.ts.txt');
diag $mech->content;
$mech->content_contains("index.html#\n");
$mech->content_like(qr{^specials/index\.muse\#\d+$}m);


$site->update({ mode => 'private' });
ok $site->cgit_integration;

foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}

$mech->get("/mirror.txt");
is $mech->status, 401;


$mech->get("/mirror.ts.txt");
is $mech->status, 401;

$mech->get('/mirror/index.html');
is $mech->status, 401;

$site->update({
               cgit_integration => 0,
               mode => 'modwiki',
              });
