#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;
use AmuseWikiFarm::Utils::Jobber;
use Text::Amuse::Compile::Templates;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;

my $site = create_site($schema, '0cformats3');

$site->update({
               ttdir => 'custom-templates',
               epub => 1,
               tex => 1,
               html => 1,
               pdf => 1,
              });
$site->check_and_update_custom_formats;
my $cf = $site->custom_formats->search({ format_alias => 'pdf' })->first;
$cf->update({
             bb_areaset_height => '40',
             bb_areaset_width => '40',
             bb_tex_tolerance => '800',
             bb_tex_emergencystretch => '50',
            });
my $cf_code = $cf->code;
my $marker = "FORMAT ID CORRECTLY PASSED $cf_code";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
my $target_dir = path($site->repo_root, $site->ttdir);
$target_dir->mkpath;

$target_dir->child('latex.tt')->spew_utf8(${ Text::Amuse::Compile::Templates->new->latex },
                                          "[% IF safe_options.format_id.$cf_code %]",
                                          $marker,
                                          "[% ELSE %]% No marker found.[% END %]");
$site->check_and_update_custom_formats;
my $muse = path($site->repo_root, qw/t tt test.muse/);
$muse->parent->mkpath;
$muse->spew_utf8(<<'MUSE');
#title Test
#lang en

Blablabla
MUSE

$site->update_db_from_tree;

run_all_jobs($schema);

{
    my $base = '/library/test';
    $mech->get_ok($base . '.tex');
    $mech->content_lacks($marker);
    $mech->content_contains('% No marker found.');
    $mech->get_ok($base . '.' . $cf_code . '.tex');
    $mech->content_contains($marker);
    $mech->content_lacks('% No marker found.');
    $mech->content_contains('tolerance=800');
    $mech->content_contains('\\setlength{\\emergencystretch}{50pt}');
    $mech->content_contains('\\setlength{\\emergencystretch}{50pt}');
    $mech->content_contains('areaset[current]{40mm}{40mm}');
}
