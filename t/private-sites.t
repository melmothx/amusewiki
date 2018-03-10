#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 331;
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
mkdir catdir($site->repo_root, 'a');
mkdir catdir($site->repo_root, 'a', 'at');
write_file(catfile($site->repo_root, 'a', 'at', 'a-test.muse'), "#title a test\n\nHello, a test\n");
write_file(catfile($site->repo_root, 'site_files', 'test.js'), "Hello\n");

$site->update_db_from_tree(sub { diag @_ });

my @uris = (qw[library category/topic category/author bookbuilder search special
               cloud monthly latest
                     opds help/opds sitemap.txt
                     feed rss.xml stats/popular]);

$mech->get_ok('/login');

check_denied('before login');

$mech->get_ok('/sitefiles/0private0/test.js');
is $mech->response->content, "Hello\n", "Sitefile retrieved";

foreach my $open (qw/login opensearch.xml/) {
    $mech->get_ok("/$open");
    is $mech->uri->path, "/$open";
}

$site->update_or_create_user({ username => 'marcolino',
                               active => 1,
                               password => 'marcolino', }, "librarian");

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'marcolino', __auth_pass => 'marcolino' });
is $mech->uri->path, '/latest', "Loaded library ok";

check_pass("After login");

$mech->get_ok("/robots.txt");
is $mech->content, "User-agent: *\nDisallow: /\n", "robots.txt ok, disallow everything";

$mech->get("/logout");
is $mech->uri->path, "/";
$mech->content_contains('login-form');

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
                                                    host => "0private0.amusewiki.org");
    $human->get('/');
    foreach my $path (@uris) {
        $human->get("/$path");
        is $human->status, 401;
        $human->content_contains('__auth_user');
        is $human->uri->path, "/$path";
    }
    $human->get('/');
    $human->get("/login");
    $human->submit_form(with_fields => { __auth_user => 'marcolino', __auth_pass => 'marcolino' });
    $human->get_ok('/');
    foreach my $path (@uris) {
        $human->get_ok("/$path");
        is $human->uri->path, "/$path", "$path is retrieved correctly after the login";
    }
}

{
    my $robot = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    agent => 'Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/9537.53 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
                                                    host => "0private0.amusewiki.org");
    foreach my $path (@uris) {
        $robot->get("/$path");
        is $robot->status, '401';
    }
    $robot->credentials(qw/marcolino marcolino/);
    foreach my $path (@uris) {
        $robot->get_ok("/$path");
    }
}

sub check_denied {
    my $note = shift;
    foreach my $path (@uris) {
        $mech->get("/$path");
        is $mech->status, '401', "401 on $path $note";
        $mech->content_contains('login-form');
    }
}
sub check_pass {
    my $note = shift;
    foreach my $path (@uris) {
        $mech->get_ok("/$path", "$path $note is 200");
        is $mech->uri->path, "/$path", "$path is retrieved correctly $note";
    }
}
