use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 27;
use File::Spec::Functions qw/catfile catdir/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $sid_first = '0xss0';
my $sid_second = '0xss1';

my $site1 = create_site($schema, $sid_first);
my $site2 = create_site($schema, $sid_second);

my $mech1 = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => "$sid_first.amusewiki.org");

my $user1 = $site1->update_or_create_user({
                                           username => 'pinco1',
                                           password => 'pallino1',
                                           active   => 1,
                                          });

$user1->set_roles([{ role => 'librarian' }]);

my $user2 = $site2->update_or_create_user({
                                           username => 'pinco2',
                                           password => 'pallino2',
                                           active   => 1,
                                          });

$user2->set_roles([{ role => 'librarian' }]);

$mech1->get_ok('/');

my $mech2 = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => "$sid_second.amusewiki.org");

$mech2->get_ok('/');

my ($res1, $res2);

$res1 = $mech1->get('/login');
$res2 = $mech2->get('/login');

# print Dumper($res1->request, $res1->headers, $res2->request, $res2->headers);

my $cookie_on_first = $res1->request->header('Cookie');
ok !$cookie_on_first, "No cookie set on first request";

$mech2->get('/login', Cookie => '');

is $mech2->status, '200', "Trying to use a session from another site is ok as long there is no cookie";

$res2 = $mech2->get('/login', Cookie => $cookie_on_first);
ok (!$res2->request->header('Cookie'), "No cookie set yet");

$mech1->get_ok('/login');
$mech1->submit_form(form_id => 'login-form',
                    fields => { username => 'pinco1', password => 'pallino2' },
                    button => 'submit');

is ($mech1->response->base->path, '/login', "wrong password, still here");

$mech1->submit_form(form_id => 'login-form',
                    fields => { username => 'pinco1', password => 'pallino1' },
                    button => 'submit');

is ($mech1->response->base->path, '/latest', "logged in");

$res1 = $mech1->get('/library');
# we are logged in
$mech1->content_contains('pinco1');
$mech1->get('/console/git');
is ($mech1->response->base->path, '/console/git', "logged in");

# and try the same trick now that we're logged in

$cookie_on_first = $res1->request->header('Cookie');
ok ($cookie_on_first, "Got the cookie");
diag "Using $cookie_on_first on another site";
$mech1->get('/console/git', Cookie => $cookie_on_first);
is ($mech1->uri->path, "/console/git", "Legit user ok");
$res2 = $mech2->get('/console/git', Cookie => $cookie_on_first);
is ($mech2->uri->path, "/login", "non-legit user not ok, bounced to login");
$mech2->content_lacks('pinco1');
ok(!$res2->header('Cookie'), "No cookie returned after stealing");
$mech2->get('/library', Cookie => $cookie_on_first);

foreach my $mech ($mech1, $mech2) {
    $mech->get('/library', Cookie => $cookie_on_first);
    # we are logged in
    $mech->content_lacks('pinco1',
                         "user on the site is now forcibly logged out");
    $mech->get('/bookbuilder', Cookie => $cookie_on_first);
    is ($mech->response->base->path, '/human',
        "logged out and session cleared, is not even recognized as human");
    $mech->get('/console/git', Cookie => $cookie_on_first);
    is ($mech->response->base->path, '/login',
        "logged out and session cleared, can't access git");
}

foreach my $mech ($mech1, $mech2) {
    $mech->get('/library');
    # we are logged in
    $mech->content_lacks('pinco1',
                         "user on the site is now forcibly logged out");
    $mech->get('/bookbuilder');
    is ($mech->response->base->path, '/human',
        "logged out and session cleared, is not even recognized as human");
    $mech->get('/console/git');
    is ($mech->response->base->path, '/login',
        "logged out and session cleared, can't access git");
}
