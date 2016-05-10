#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 232;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0private0');
$site->update({ mode => 'private',
                secure_site => 0 });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "0private0.amusewiki.org");


ok -d $site->repo_root;
mkdir catdir($site->repo_root, 'site_files');
write_file(catfile($site->repo_root, 'site_files', 'test.txt'), "Hello\n");

my @uris = (qw[library category/topic category/author bookbuilder search special
                     opds help/opds sitemap.txt
                     feed rss.xml stats/popular]);

$mech->get_ok('/login');

check_denied('before login');

$mech->get_ok('/sitefiles/0private0/test.txt');
is $mech->response->content, "Hello\n", "Sitefile retrieved";

foreach my $open (qw/login opensearch.xml/) {
    $mech->get_ok("/$open");
    is $mech->uri->path, "/$open";
}

$site->update_or_create_user({ username => 'marcolino',
                               active => 1,
                               password => 'marcolino', }, "librarian");

$mech->get_ok('/login');
ok $mech->form_with_fields('username');
$mech->set_fields(username => 'marcolino',
                  password => 'marcolino');
$mech->click;
is $mech->uri->path, '/library', "Loaded library ok";

check_pass("After login");

$mech->get_ok("/robots.txt");
is $mech->content, "User-agent: *\nDisallow: /\n", "robots.txt ok, disallow everything";

$mech->get_ok("/logout");

check_denied('after logout');

$mech->credentials(qw/marcolino marcolino/);

check_pass('with http auth');

$site->set_users([]);

check_denied('after user deletion');

my $user = $schema->resultset('User')->find({ username => 'marcolino'});
ok($user, "User still exists");

$site->set_users([$user]);

check_pass('after adding user to site');

$user->update({ active => 0 });

check_denied('after setting inactive to 0');

$user->update({ active => 1 });

{
    my $human = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    agent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.89 Safari/537.36",
                                                    max_redirect => 0,
                                                    host => "0private0.amusewiki.org");

    foreach my $path (@uris) {
        $human->get("/$path");
        is $human->status, '302';
        diag $human->response->headers->header('Location');
        like $human->response->headers->header('Location'), qr{0private0\.amusewiki\.org/login}, "Redirected to login";
    }
    $human->get("/login");
    ok $human->form_with_fields('username');
    $human->set_fields(username => 'marcolino',
                      password => 'marcolino');
    $human->click;
    foreach my $path (@uris) {
        $human->get_ok("/$path");
        is $human->uri->path, "/$path", "$path is retrieved correctly after the login";
    }
}


sub check_denied {
    my $note = shift;
    foreach my $path (@uris) {
        $mech->get("/$path");
        is $mech->status, '401', "401 on $path $note";
        $mech->content_is('Authorization required.', "$path $note");
    }
}
sub check_pass {
    my $note = shift;
    foreach my $path (@uris) {
        $mech->get_ok("/$path", "$path $note is 200");
        is $mech->uri->path, "/$path", "$path is retrieved correctly $note";
    }
}
