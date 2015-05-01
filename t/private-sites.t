#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 42;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0private0');
$site->update({ mode => 'private',
                secure_site => 0 });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "0private0.amusewiki.org");


ok -d $site->repo_root;
mkdir catdir($site->repo_root, 'site_files');
write_file(catfile($site->repo_root, 'site_files', 'test.txt'), "Hello\n");

$mech->get_ok('/login');

foreach my $path (qw/library topics authors bookbuilder search special
                     feed rss.xml random human/) {
    $mech->get_ok("/$path");
    is $mech->uri->path, '/login', "/$path is redirected at login";
}

$mech->get_ok('/sitefiles/0private0/test.txt');
is $mech->response->content, "Hello\n", "Sitefile retrieved";

$site->update_or_create_user({ username => 'marcolino',
                               password => 'marcolino', }, "librarian");

$mech->get_ok('/login');
$mech->form_with_fields('username');
$mech->set_fields(username => 'marcolino',
                  password => 'marcolino');
$mech->click;
is $mech->uri->path, '/library', "Loaded library ok";

foreach my $path (qw[library category/topic category/author bookbuilder search special
                     feed rss.xml]) {
    $mech->get_ok("/$path");
    is $mech->uri->path, "/$path", "/$path is retrieved correctly";
}


