#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 15;
use Data::Dumper;
use Cwd;
use File::Spec;

use AmuseWikiFarm::Schema;

my $db = AmuseWikiFarm::Schema->connect('amuse');

ok($db);

my $site = $db->resultset('Site')->find('0test0');

ok($site);

my %formats = $site->available_formats;

is_deeply \%formats, {
                      'bare_html' => 1,
                      'pdf' => 1,
                      'zip' => 1,
                      'html' => 1,
                      'lt_pdf' => 0,
                      'tex' => 1,
                      'a4_pdf' => 0,
                      'epub' => 1
                     };

my %exts = $site->available_text_exts;

is_deeply \%exts, {
                   '.bare.html' => 1,
                   '.pdf' => 1,
                   '.zip' => 1,
                   '.html' => 1,
                   '.lt.pdf' => 0,
                   '.tex' => 1,
                   '.a4.pdf' => 0,
                   '.epub' => 1
                  };

my $test = $site->titles->random_text;

like $test->html_body, qr/<p>/, "Found the HTML body";
like $test->muse_body, qr/#title/, "Found the muse body";

ok (!$site->archive_root);
is ($site->repo_root, File::Spec->catdir(getcwd(), repo => $site->id));

my $targetdir = $site->path_for_file("che-cacca");

is ($targetdir, File::Spec->catdir($site->repo_root,
                                   qw/c cc/));

diag "Found $targetdir";
rmdir $targetdir if -d $targetdir;
ok (-d $site->path_for_file("che-cacca"));

is ($site->mode, 'blog');

$site = $db->resultset('Site')->find('0blog0');

is $site->repo_root_rel, File::Spec->catdir('repo', '0blog0');
is $site->repo_root, File::Spec->catdir(getcwd(), 'repo', '0blog0');

my $tmp = File::Spec->tmpdir;

is $site->repo_root($tmp), File::Spec->catdir($tmp, qw/repo 0blog0/);

is $site->repo_root(0), File::Spec->catdir(getcwd(), 0, qw/repo 0blog0/);


