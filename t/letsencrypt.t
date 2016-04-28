#!perl

use strict;
use warnings;
use Test::More tests => 24;
use AmuseWikiFarm::Utils::LetsEncrypt;
use Path::Tiny;

my $dir = Path::Tiny->tempdir(CLEANUP => 1, TEMPLATE => 'LE_LIVE_XXXXXXXXX');
my $root = Path::Tiny->tempdir(CLEANUP => 1, TEMPLATE => 'LE_WD_XXXXXXXXX');;

my $le = AmuseWikiFarm::Utils::LetsEncrypt->new(directory => "$dir",
                                                mailto => 'melmothx@gmail.com',
                                                names => [qw/testing.amusewiki.org
                                                             staging.amusewiki.org/],
                                                root => "$root");
ok(!$le->live_cert_is_valid, "No cert, no party");

ok ($le->account_key);
ok (-f $le->account_key, $le->account_key . " exists");
foreach my $method (qw/csr key cert chain fullchain/) {
    ok ($le->$method, "$method is " . $le->$method);
    my $live = "live_$method";
    ok ($le->$live, "$live is " . $le->$live);
}
diag $le->_openssl_config_body;
$le->process;

my $fake_cert = <<'CERT';
-----BEGIN CERTIFICATE-----
MIIFNTCCBB2gAwIBAgITAPq5BT6RdE7/PMAXzftVs8uNBTANBgkqhkiG9w0BAQsF
ADAiMSAwHgYDVQQDDBdGYWtlIExFIEludGVybWVkaWF0ZSBYMTAeFw0xNjA0Mjgw
NzA0MDBaFw0xNjA3MjcwNzA0MDBaME8xHjAcBgNVBAMTFXRlc3RpbmcuYW11c2V3
aWtpLm9yZzEtMCsGA1UEBRMkZmFiOTA1M2U5MTc0NGVmZjNjYzAxN2NkZmI1NWIz
Y2I4ZDA1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAreJ8Y7vFKEJj
I2chKD/fyrBH3h0h2PDVAF5hZ/OgE7rHrouttH9OxB3urJGaSboI3fGydnPTW/Tx
EEvZb1ZZ6Y4sO+jfQw5sXlzTcj8cLuPbakPqkbPBGHnnDAKIHC9/muBVVuKyY71o
bRiNDwT2Fv+RHqua2A4Iiy16dLVyg190DoReU2Fsyz8pZNAwWHi4+1VDorh3pN7W
2+TuxrGdjjkDFPz5FJpmevDH9vKJh0FO2kWASnbE+wLNW+3H4QORPGV6q0W6i8/c
U3A4/b9GHUrNzPW643aiWzKR15U9ryXt+U0K/AQfxTU3HT6l+fkBx1gE6qgcObGc
PUHLtZmxTQIDAQABo4ICNTCCAjEwDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQG
CCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTuzV3c
FHv8LOabj3JiudoLzU4dbTAfBgNVHSMEGDAWgBTAzANGuVggzFxycPPhLssgpvVo
OjB4BggrBgEFBQcBAQRsMGowMwYIKwYBBQUHMAGGJ2h0dHA6Ly9vY3NwLnN0Zy1p
bnQteDEubGV0c2VuY3J5cHQub3JnLzAzBggrBgEFBQcwAoYnaHR0cDovL2NlcnQu
c3RnLWludC14MS5sZXRzZW5jcnlwdC5vcmcvMDcGA1UdEQQwMC6CFXN0YWdpbmcu
YW11c2V3aWtpLm9yZ4IVdGVzdGluZy5hbXVzZXdpa2kub3JnMIH+BgNVHSAEgfYw
gfMwCAYGZ4EMAQIBMIHmBgsrBgEEAYLfEwEBATCB1jAmBggrBgEFBQcCARYaaHR0
cDovL2Nwcy5sZXRzZW5jcnlwdC5vcmcwgasGCCsGAQUFBwICMIGeDIGbVGhpcyBD
ZXJ0aWZpY2F0ZSBtYXkgb25seSBiZSByZWxpZWQgdXBvbiBieSBSZWx5aW5nIFBh
cnRpZXMgYW5kIG9ubHkgaW4gYWNjb3JkYW5jZSB3aXRoIHRoZSBDZXJ0aWZpY2F0
ZSBQb2xpY3kgZm91bmQgYXQgaHR0cHM6Ly9sZXRzZW5jcnlwdC5vcmcvcmVwb3Np
dG9yeS8wDQYJKoZIhvcNAQELBQADggEBAErtXiPiQ1qdDlwVTEk3VzYNiuC6alPY
5cMzSPQhpRdEyEXPX+aNF06T5LAUHbBj2xutvAAMZ39HVl+EgtwNwH1atjc94/Qs
QqRh4L0ZPXHTlMmsglPlMPVfu8VT/6M9Av9BBSYf+wK9/GntSxuggSrVgTfmzUh8
SorAlTmTwsW3G3WinKBtd0YRRBQnOdosjvx+7GeTky4l3FsQqtLJYonRYRAI8qAb
OBabfWz7k5OGIod2RNkken1/toky79+i9jY7v1sEHwy8Fe4BT35viww7Umjb3gnZ
5bV44QPWpaAl9qQNB2Bsj7eNL8yEAnQ8cBuNq9zZ7Gip26TFmhhfaO0=
-----END CERTIFICATE-----
CERT

foreach my $method (qw/csr key cert chain fullchain/) {
    unless ($le->$method->exists) {
        diag "Populating " . $le->$method;
        $le->$method->spew('blabla');
    }
}
$le->live_cert->spew($fake_cert);
ok($le->live_cert_names_ok, "All the names are in");
ok $le->live_cert_object->extensions_by_oid->{"2.5.29.17"}->to_string, "Found SAN";
diag $le->live_cert_object->extensions_by_oid->{"2.5.29.17"}->to_string;
diag $le->live_cert_object->subject;
diag "Installing empty certs";
$le->_backup_and_install;
$le->live_cert->spew($fake_cert);
ok (path($le->directory)->child($le->now_string)->exists, "Found the backup directory");

ok (defined $le->live_cert_is_valid, "Checked cert: " . $le->live_cert_is_valid);
ok (defined $le->live_cert_expiration_ok, "Expiration: " . $le->live_cert_expiration_ok);

foreach my $method (qw/csr key cert chain fullchain/) {
    my $live = "live_" . $method;
    ok($le->$live->exists, $le->$live . " exists");
}
ok (1, "Reached the end");
