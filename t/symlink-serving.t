#!perl

# This is probably a redundant test, but given that it's a delicate
# part of the code, better safe than sorry.
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;

use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 5;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0symlinks0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $css = catfile($site->path_for_site_files, 'local.css');
write_file($css, '/* */');
my $js = catfile($site->path_for_site_files, 'local.js');
unlink $js if -f $js;
symlink $css, $js;

ok ($site->has_site_file('local.css'));
ok ($site->has_site_file('local.js'));
ok (-f $js && -l $js, "$js exists and it's a symlink");


$mech->get_ok('/sitefiles/' . $site->id . '/local.css');
$mech->get('/sitefiles/' . $site->id . '/local.js');
is $mech->status, 404, "Symlink return a 404";
