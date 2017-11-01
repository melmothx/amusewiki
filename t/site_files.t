#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 88;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Data::Dumper;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0sf2';
my $site = create_site($schema, $site_id);

ok(-f catfile($site->repo_root, '.gitignore'), "gitignore was created");
ok ($site->git, "Git was initialized with ->initialize_git");
like (read_file(catfile($site->repo_root, '.gitignore')),
      qr{\?/\?\?/\*\.pdf});


ok(!$site->logo_with_sitename, "By default, the logo has not a sitename");

$site->update({ sitename => 'Blabla' });
my %compile_options = $site->compile_options;

is $compile_options{extra}{sitename}, 'Blabla', "Sitename in the options";
$site->update({ logo_with_sitename => 1 });
%compile_options = $site->compile_options;
is $compile_options{extra}{sitename}, '', "sitename option nulled out";



my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");



my $basedir = $site->path_for_site_files;
like $basedir, qr/\Q$site_id\E.\Qsite_files\E/ or die $basedir;

my @good = (qw/test.torrent test.ico
               test.jpg test.jpeg test.gif test.png
               test.ttf test.woff test.otf
               test.js test.css
              /);
my @bad = (".tryme.torrent", "test me.exe", "hullo_therer.ciao", "lexicon.json",
           "fontspec.json", "file.exe", "adsf.", "test.txt");

foreach my $file (@good, @bad) {
    my $testfile = catfile($basedir, $file);
    write_file($testfile, "xxx\n");
    ok (-f $testfile, "$testfile found");
}

$site->index_site_files;

foreach my $good_one (@good) {
    $mech->get_ok("/sitefiles/$site_id/$good_one");
}

foreach my $bad_one (@bad) {
    $mech->get("/sitefiles/$site_id/$bad_one");
    is $mech->status, '404', "/sitefiles/$site_id/$bad_one not found";
    $mech->get("/sitefiles/$site_id/subdir/$bad_one");
    is $mech->status, '404', "/sitefiles/$site_id/subdir/$bad_one not found";
}

# default layout, so check the favicon

my @localfiles = (qw/local.css local.js/);

foreach my $localf (@localfiles) {
    $mech->get('/');
    my $uri = "/sitefiles/$site_id/$localf";
    $mech->content_contains(qq{$localf"});
    $mech->get_ok($uri);
    $mech->content_contains('Empty by default');
}

$site->site_files->update({ file_path => '/etc/passwd' });

foreach my $f ($site->site_files) {
    if ($f->is_public) {
        my $localf = $f->file_name;
        diag "GET /sitefiles/$site_id/$localf";
        $mech->get("/sitefiles/$site_id/$localf");
        is $mech->status, 403;
        is $mech->content, 'Access denied';
    }
}

# delete and recheck
foreach my $localf (@localfiles) {
    my $testfile = catfile($basedir, $localf);
    unlink $testfile or die "Couldn't unlink $testfile $!";
}
$site->index_site_files;
$mech->get_ok('/');
foreach my $localf (@localfiles) {
    $mech->content_lacks($localf);
}

