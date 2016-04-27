#!perl

use strict;
use warnings;
use Test::More tests => 4;
use AmuseWikiFarm::Utils::LetsEncrypt;
use Path::Tiny;

my $dir = Path::Tiny->tempdir(CLEANUP => 0);
my $root = Path::Tiny->tempdir;

my $le = AmuseWikiFarm::Utils::LetsEncrypt->new(directory => "$dir",
                                                mailto => 'melmothx@gmail.com',
                                                names => [qw/testing.amusewiki.org
                                                             staging.amusewiki.org/],
                                                root => "$root");

ok ($le->account_key);
ok (-f $le->account_key);
ok ($le->cert_key);
diag $le->cert_key;
diag $le->account_key;
diag $le->_openssl_config_body;
$le->process;
ok (1, "Reached the end");

