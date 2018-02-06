#!perl

use utf8;
use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Warn;
use Test::WWW::Mechanize::Catalyst;
use lib "$FindBin::Bin/lib";
use Data::Dumper::Concise;
use HTTP::Cookies;
use AmuseWikiFarm::Schema;

plan tests => 108;

my @mechs = (Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "blog.amusewiki.org",
                                                 cookie_jar => HTTP::Cookies->new,
                                                ),
             Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "test.amusewiki.org",
                                                 cookie_jar => HTTP::Cookies->new,
                                                ),
             Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "blog.amusewiki.org",
                                                 cookie_jar => HTTP::Cookies->new,
                                                ),
             Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "test.amusewiki.org",
                                                 cookie_jar => HTTP::Cookies->new,
                                                ));

my $schema = AmuseWikiFarm::Schema->connect('amuse');

# remove all existing sessions
$schema->resultset('AmwSession')->delete;

my $key   = 'schema';
my $value = scalar localtime;

for my $mech (@mechs) {
    # weirdness to make the cookie jar kick in...
    $mech->get('http://' . $mech->host . '/');
    diag $mech->response->as_string;
    ok !$mech->response->header('Set-Cookie');
}

my %cookies;

for my $mech (@mechs) {
    # Setup session
    $mech->get_ok("/session/setup?key=$key&value=$value", 'request to set session value');
    diag $mech->response->as_string;
    ok $mech->response->header('Set-Cookie');
    my $sx_cookie;
    $mech->cookie_jar->scan(sub { my @all = @_; $sx_cookie = $all[2] });
    $mech->{___amw_store_sx_cookie} = $sx_cookie;
    ok $sx_cookie, "Found cookie $sx_cookie";
    $cookies{$sx_cookie} = 1;
    $mech->content_is('ok', 'set session value');
}

is (scalar(keys %cookies), 4, "4 sessions open");

# Setup flash
for my $mech (@mechs) {
    $mech->get_ok("/flash/setup?key=$key&value=$value", 'request to set flash value');
    ok(index($mech->response->header('Set-Cookie'), $mech->{___amw_store_sx_cookie}) > 0,
       $mech->response->header('Set-Cookie') . "contains  $mech->{___amw_store_sx_cookie}");

    ok ($schema->resultset('AmwSession')
        ->search({ session_id => { -like => '%' . $mech->{___amw_store_sx_cookie} . '%' }})->count,
        "Session cleaned up in the db") or die;

    $mech->content_is('ok', 'set flash value');
}
# Check flash
for my $mech (@mechs) {
    $mech->get_ok("/flash/output?key=$key", 'request to get flash value');
    ok(index($mech->response->header('Set-Cookie'), $mech->{___amw_store_sx_cookie}) > 0,
       $mech->response->header('Set-Cookie') . "contains  $mech->{___amw_store_sx_cookie}");

    ok ($schema->resultset('AmwSession')
        ->search({ session_id => { -like => '%' . $mech->{___amw_store_sx_cookie} . '%' }})->count,
        "Session cleaned up in the db") or die;

    $mech->content_is($value, 'got flash value back');
}

# Check session
for my $mech (@mechs) {
    $mech->get_ok("/session/output?key=$key", 'request to get session value');
    ok(index($mech->response->header('Set-Cookie'), $mech->{___amw_store_sx_cookie}) > 0,
       $mech->response->header('Set-Cookie') . "contains  $mech->{___amw_store_sx_cookie}");

    ok ($schema->resultset('AmwSession')
        ->search({ session_id => { -like => '%' . $mech->{___amw_store_sx_cookie} . '%' }})->count,
        "Session cleaned up in the db") or die;

    $mech->content_is($value, 'got session value back');
}

# Delete session
for my $mech (@mechs) {
    $mech->get_ok('/session/delete', 'request to delete session');
    ok(index($mech->response->header('Set-Cookie'), $mech->{___amw_store_sx_cookie}) > 0,
       $mech->response->header('Set-Cookie') . "contains  $mech->{___amw_store_sx_cookie}");
    ok (!$schema->resultset('AmwSession')
        ->search({ session_id => { -like => '%' . $mech->{___amw_store_sx_cookie} . '%' }})->count,
        "Session cleaned up in the db") or die;
    $mech->content_is('ok', 'deleted session');
}

# Delete expired sessions
for my $mech (@mechs) {
    ok(index($mech->response->header('Set-Cookie'), $mech->{___amw_store_sx_cookie}) > 0,
       $mech->response->header('Set-Cookie') . "contains  $mech->{___amw_store_sx_cookie}");

    $mech->get_ok('/session/delete_expired', 'request to delete expired sessions');
    $mech->content_is('ok', 'deleted expired sessions');
}

my $site = $schema->resultset('Site')->find('0blog0');

my $engine = $site->amw_sessions;

foreach my $prefix (qw/session flash blbabla/) {
    my $k = "key";
    my $value = "dđ jadsfćč sŠ";
    my $sid = $prefix . ':' . $k;
    $engine->store_session_data($sid, $value);
    is $engine->get_session_data($sid), $value;

    $engine->store_session_data($sid, [ $value ] );
    is_deeply $engine->get_session_data($sid), [ $value ];

    $engine->store_session_data($sid, {  $value => 1  } );
    is_deeply $engine->get_session_data($sid), { $value => 1 };

}

eval { $schema->resultset('AmwSession')->store_session_data('expires:2', 1) };
ok $@, "Cannot store data without a site $@";


$engine->store_session_data('expires:2', { 'hello' => 1  });
is $engine->get_session_data('expires:2'), undef, "Cannot store arbitrary data in expires";

$engine->store_session_data('expires:2', 20);
is $engine->get_session_data('expires:2'), 20;

eval { $schema->resultset('AmwSession')->get_session_data('expires:2') };
ok $@, "Cannot retrieve data without a site";


