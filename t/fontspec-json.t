#!perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 22;

my ($main_font, $removed_font) = ("CMU Sans Serif", "Linux Libertine O");
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0fonts0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $filedir = catdir($site->repo_root, qw/a at/);
make_path($filedir);
my $text = 'a-test';
write_file(catfile($filedir, $text . '.muse'), "#title A Test\n\nbla bla bla\n");
$site->update_db_from_tree;
$mech->get_ok('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/library/' . $text);
$mech->get_ok('/bookbuilder/add/' . $text);

my @pages_with_fonts = (
                        '/admin/sites/edit/' . $site->id,
                        '/bookbuilder',
                        '/bookbuilder/fonts',
                       );

foreach my $page (@pages_with_fonts) {
    $mech->get_ok($page);
    $mech->content_contains($removed_font);
    $mech->content_contains($main_font);
}

my $json =<<JSON;
[
   {
      "desc" : "CMU Serif",
      "name" : "CMU Serif",
      "type" : "serif"
   },
   {
      "desc" : "CMU Sans Serif",
      "name" : "CMU Sans Serif",
      "type" : "sans"
   },
   {
      "desc" : "CMU Typewriter Text",
      "name" : "CMU Typewriter Text",
      "type" : "mono"
   }
]
JSON

write_file(catfile($site->path_for_site_files, 'fontspec.json'), $json);

foreach my $page (@pages_with_fonts) {
    $mech->get_ok($page);
    $mech->content_lacks($removed_font);
    $mech->content_contains($main_font);
}

