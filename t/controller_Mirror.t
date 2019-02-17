#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 88;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Paths;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

$site->generate_static_indexes(sub { diag @_ });

{
    my $src_dir = AmuseWikiFarm::Utils::Paths::static_file_location();
    my $indexes = $site->static_indexes_generator;
    foreach my $css ($indexes->css_files) {
        my $path = path($src_dir, $css);
        if ($path->basename eq 'fork-awesome.css' or
            $path->basename eq 'fork-awesome.min.css') {
            my $body = $path->slurp_raw;
            $body =~ s/url\((.+?)(\?[^\)]*?)?\)/url($1)/g;
            unlike $body, qr{v=}, "$path is without font versioning";
        }
    }
}


my $cache = path($site->mirror_list_file);
if ($cache->exists) {
    $cache->remove;
}

ok !$cache->exists;
ok $site->list_files_for_mirroring;
ok $cache->exists;
$cache->remove;
ok !$cache->exists;

while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

ok $cache->exists or die;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my @paths = (qw[
                   authors.html 
                   titles.html topics.html site_files/navlogo.png 
                   site_files/favicon.ico
                   site_files/__static_indexes/fonts/forkawesome-webfont.ttf
              ]);

# private mode: always deny

$site->update({ mode => 'private' });
$site->site_options->search({ option_name => 'restrict_mirror' })->delete;

foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}
$mech->get('/robots.txt');
$mech->content_lacks('http://blog.amusewiki.org/mirror.txt | wget');

# public mode, no restrict_mirror, ok

$site->update({ mode => 'blog' });

$mech->get('/robots.txt');
$mech->content_contains('http://blog.amusewiki.org/mirror.txt | wget');

foreach my $path (@paths) {
    $mech->get_ok("/mirror/$path");
}

# public mode: deny if restrict_mirror is active

$site->site_options->update_or_create({
                                       option_name => 'restrict_mirror',
                                       option_value => 1,
                                      });
$mech->get_ok('/robots.txt');
$mech->content_lacks('http://blog.amusewiki.org/mirror.txt | wget');
foreach my $path (@paths) {
    $mech->get("/mirror/$path");
    is $mech->status, 401;
}

# public mode, no restrict_mirror, ok

$site->site_options->update_or_create({
                                       option_name => 'restrict_mirror',
                                       option_value => '',
                                      });

$mech->get('/robots.txt');
$mech->content_contains('http://blog.amusewiki.org/mirror.txt | wget');
foreach my $path (@paths) {
    $mech->get_ok("/mirror/$path");
}
$mech->get('/robots.txt');
$mech->content_contains('http://blog.amusewiki.org/mirror.txt | wget');

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

my @denied = (qw/exe pl aux toc po json tt/);

my @test_denied;
foreach my $deny (@denied) {
    my $testfile = path($site->titles->published_texts->first->path_tiny . '.' . $deny);
    diag "Creating $testfile";
    $testfile->spew('blah');
    push @test_denied, $testfile;
}

$mech->get_ok('/mirror.ts.txt');
diag $mech->content;
$mech->content_contains("index.html#\n");
$mech->content_like(qr{^specials/index\.muse\#\d+$}m);

foreach my $deny (@denied) {
    $mech->content_lacks('.' . $deny . '#');
}

$site->update({ mode => 'private' });

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

$site->update({ mode => 'modwiki' });

foreach my $testfile (@test_denied) {
    ok $testfile->remove;
}

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/user/site');
$mech->form_with_fields(qw/restrict_mirror/);
$mech->tick(restrict_mirror => 'ON');
$mech->click;

$site = $site->get_from_storage;
ok $site->restrict_mirror;

$mech->get_ok('/user/site');
$mech->form_with_fields(qw/restrict_mirror/);
$mech->untick(restrict_mirror => 'ON');
$mech->click;

$site = $site->get_from_storage;
ok !$site->restrict_mirror;

$mech->get_ok('/mirror/site_files/__static_indexes/css/fork-awesome.min.css');
$mech->content_contains(q{url(../fonts/forkawesome-webfont.eot) format('embedded-opentype')});
$mech->content_contains(q{url(../fonts/forkawesome-webfont.woff2) format('woff2')});
