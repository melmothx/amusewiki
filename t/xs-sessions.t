use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 33;
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

$site1->amw_sessions->delete;
$site2->amw_sessions->delete;

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

my $res1 = $mech1->get('/login');
my $res2 = $mech2->get('/login');

# print Dumper($res1->request, $res1->headers, $res2->request, $res2->headers);

$mech1->get_ok('/login');
$mech1->submit_form(with_fields => { __auth_user => 'pinco1', __auth_pass => 'pallino2' });
is ($mech1->response->base->path, '/login', "wrong password, still here");
$mech1->submit_form(with_fields => { __auth_user => 'pinco1', __auth_pass => 'pallino1' });
is ($mech1->response->base->path, '/latest', "logged in");
$mech1->content_contains('/logout');

$res1 = $mech1->get('/library');
# we are logged in
$mech1->content_contains('pinco1');
$mech1->get_ok('/console/git');

# and try the same trick now that we're logged in

my $cookie_on_first = $res1->request->header('Cookie');
ok ($cookie_on_first, "Got the cookie");
diag "Using $cookie_on_first on another site";
$mech1->get('/console/git', Cookie => $cookie_on_first);
is ($mech1->uri->path, "/console/git", "Legit user ok");

is $site2->amw_sessions->count, 1;
is $site1->amw_sessions->count, 1;

# here we use the cookie for against another site
{
    diag "Hitting " . $mech2->host . " with $cookie_on_first";
    $res2 = $mech2->get('/console/git', Cookie => $cookie_on_first);
    is $mech2->status, 401;
    $mech2->content_lacks('pinco1');
    ok(!$res2->header('Cookie'), "No cookie returned after stealing");
    # library
    $mech2->get('/library', Cookie => $cookie_on_first);
    $mech2->content_lacks('pinco1');
    ok $mech2->response->header('Set-Cookie');
    is $site2->amw_sessions->count, 2;
    diag $mech2->response->header('Set-Cookie');
    # bookbuilder
    $mech2->get('/bookbuilder', Cookie => $cookie_on_first);
    is $site2->amw_sessions->count, 3;
    ok $mech2->response->header('Set-Cookie');
    diag $mech2->response->header('Set-Cookie');
    is $mech2->status, 401;
    $mech2->content_contains('__auth_human');
    # console/git
    $mech2->get('/console/git', Cookie => $cookie_on_first);
    ok $mech2->response->header('Set-Cookie');
    diag $mech2->response->header('Set-Cookie');
    is $site2->amw_sessions->count, 4;
    is $mech2->status, 401, "can't access git";
}
{
    diag "getting /library using $cookie_on_first";
    # library
    $mech1->get('/library', Cookie => $cookie_on_first);
    is $mech1->status, 200;
    $mech1->get('/console/git', Cookie => 'amusewikifarm_session=3e627aca67b24e7626aefba81e6466217de2e6d5');
    is $mech1->status, 401;

    is $site1->amw_sessions->count, 2, "only one session spawned";

    $mech1->get('/library', Cookie => $cookie_on_first);
    is $mech1->status, 200;

    # we are logged in
    $mech1->content_contains('pinco1', "Nothing happened on " . $mech1->host);
    # bookbuilder
    $mech1->get('/bookbuilder', Cookie => $cookie_on_first);
    is $mech1->status, 200;
    $mech1->content_lacks('__auth_human');
    # git
    is $mech1->status, 200;
    $mech1->get('/console/git', Cookie => $cookie_on_first);
}


