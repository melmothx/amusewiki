#!perl

use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Warn;
use Test::WWW::Mechanize::Catalyst;
use lib "$FindBin::Bin/lib";

plan tests => 24;

my $mech_1 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "blog.amusewiki.org",
                                                );

my $mech_2 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'TestApp',
                                                 host => "test.amusewiki.org",
                                                );

my $key   = 'schema';
my $value = scalar localtime;

for my $mech ($mech_1, $mech_2) {
    # Setup session
    $mech->get_ok("http://localhost/session/setup?key=$key&value=$value", 'request to set session value');
    $mech->content_is('ok', 'set session value');
}

# Setup flash
for my $mech ($mech_1, $mech_2) {
    $mech->get_ok("http://localhost/flash/setup?key=$key&value=$value", 'request to set flash value');
    $mech->content_is('ok', 'set session value');
}
# Check flash
for my $mech ($mech_1, $mech_2) {
    $mech->get_ok("http://localhost/flash/output?key=$key", 'request to get flash value');
    $mech->content_is($value, 'got session value back');
}

# Check session
for my $mech ($mech_1, $mech_2) {
    $mech->get_ok("http://localhost/session/output?key=$key", 'request to get session value');
    $mech->content_is($value, 'got session value back');
}

# Delete session
for my $mech ($mech_1, $mech_2) {
    $mech->get_ok('http://localhost/session/delete', 'request to delete session');
    $mech->content_is('ok', 'deleted session');
}

# Delete expired sessions
for my $mech ($mech_1, $mech_2) {
    $mech->get_ok('http://localhost/session/delete_expired', 'request to delete expired sessions');
    $mech->content_is('ok', 'deleted expired sessions');
}
