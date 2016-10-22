#!perl

use strict;
use warnings;

use Test::More tests => 26;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0ssl0';
my $site = create_site($schema, $site_id);

$site->update({ secure_site => 1});

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok('/?__language=en'); # set the lang to get a cookie
is $mech->uri->scheme, 'http', "Getting the root leads to a plain site";
diag session($mech);
my $current_session = session($mech);
ok $current_session, "Got a session on plain";
$mech->get_ok('/login');
is $mech->uri->scheme, 'https', "/login redirects to secure site";
isnt session($mech), $current_session, "Sessionid changed after redirect";
$current_session = session($mech);

# login then

ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
   "Found the form");

is $mech->uri->scheme, 'https', 'still in https';
isnt session($mech), $current_session, "Sessionid changed after login";
$current_session = session($mech);


$mech->get_ok("http://$site_id.amusewiki.org/admin/sites");
diag session($mech);
is $mech->uri->scheme, 'https', 'still in https despite being asked a plain one';
isnt session($mech), $current_session, "Sessionid changed after redirect";
$current_session = session($mech);

$mech->get_ok("http://$site_id.amusewiki.org/");
diag session($mech);
is $mech->uri->scheme, 'https', "Authenticated can't get a plain page";
isnt session($mech), $current_session, "Sessionid changed after redirect";
$current_session = session($mech);

$mech->get_ok('/logout');
$mech->get_ok("http://$site_id.amusewiki.org");
is $mech->uri->scheme, 'http', "Non authenticated can get a plain page";

foreach my $uri (qw/login reset-password/) {
    $mech->get_ok("http://$site_id.amusewiki.org/$uri");
    is $mech->uri->scheme, 'https', "Login is ssl again";
    diag session($mech);
    isnt session($mech), $current_session, "Sessionid changed after redirect";
    $current_session = session($mech);
}
$mech->get("http://$site_id.amusewiki.org/reset-password/prova/prova");
is $mech->uri->scheme, 'https', "reset-password is ssl again";
isnt session($mech), $current_session, "Sessionid changed after redirect";
$current_session = session($mech);

diag session($mech);

sub session {
    my $mech = shift;
    my ($session) = $mech->response->header('Set-Cookie') =~ m/session=(.*?);/;
    return $session;
}
