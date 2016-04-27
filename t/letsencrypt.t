#!perl

use strict;
use warnings;
use Test::More tests => 9;
use AmuseWikiFarm::Utils::LetsEncrypt;
use Path::Tiny;

my $dir = Path::Tiny->tempdir(CLEANUP => 1, TEMPLATE => 'liveXXXXXXXXX');
my $root = Path::Tiny->tempdir;

my $le = AmuseWikiFarm::Utils::LetsEncrypt->new(directory => "$dir",
                                                mailto => 'melmothx@gmail.com',
                                                names => [qw/testing.amusewiki.org
                                                             staging.amusewiki.org/],
                                                root => "$root");

ok ($le->account_key);
ok (-f $le->account_key, $le->account_key . " exists");
foreach my $method (qw/csr key fullchain/) {
    ok ($le->$method, "$method is " . $le->$method);
    my $live = "live_$method";
    ok ($le->$live, "$live is " . $le->$live);
}
diag $le->_openssl_config_body;
$le->process;
ok (1, "Reached the end");

