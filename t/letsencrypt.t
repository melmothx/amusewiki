#!perl

use strict;
use warnings;
use Test::More tests => 18;
use AmuseWikiFarm::Utils::LetsEncrypt;
use Path::Tiny;

my $dir = Path::Tiny->tempdir(CLEANUP => 1, TEMPLATE => 'LE_LIVE_XXXXXXXXX');
my $root = Path::Tiny->tempdir(CLEANUP => 1, TEMPLATE => 'LE_WD_XXXXXXXXX');;

my $le = AmuseWikiFarm::Utils::LetsEncrypt->new(directory => "$dir",
                                                mailto => 'melmothx@gmail.com',
                                                names => [qw/testing.amusewiki.org
                                                             staging.amusewiki.org/],
                                                root => "$root");

ok ($le->account_key);
ok (-f $le->account_key, $le->account_key . " exists");
foreach my $method (qw/csr key cert chain fullchain/) {
    ok ($le->$method, "$method is " . $le->$method);
    my $live = "live_$method";
    ok ($le->$live, "$live is " . $le->$live);
}
diag $le->_openssl_config_body;
$le->process;
foreach my $method (qw/csr key cert chain fullchain/) {
    unless ($le->$method->exists) {
        diag "Populating " . $le->$method;
        $le->$method->spew('blabla');
    }
}
diag "Installing empty certs";
$le->_backup_and_install;

foreach my $method (qw/csr key cert chain fullchain/) {
    my $live = "live_" . $method;
    ok($le->$live->exists, $le->$live . " exists");
}
ok (1, "Reached the end");

