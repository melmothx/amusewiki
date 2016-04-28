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
-----BEGIN CERTIFICATE-----
MIIEqTCCApGgAwIBAgIRAIvhKg5ZRO08VGQx8JdhT+QwDQYJKoZIhvcNAQELBQAw
GjEYMBYGA1UEAwwPRmFrZSBMRSBSb290IFgxMB4XDTE2MDMyMzIyNTkwNFoXDTM2
MDMyMzIyNTkwNFowIjEgMB4GA1UEAwwXRmFrZSBMRSBJbnRlcm1lZGlhdGUgWDEw
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDtWKySDn7rWZc5ggjz3ZB0
8jO4xti3uzINfD5sQ7Lj7hzetUT+wQob+iXSZkhnvx+IvdbXF5/yt8aWPpUKnPym
oLxsYiI5gQBLxNDzIec0OIaflWqAr29m7J8+NNtApEN8nZFnf3bhehZW7AxmS1m0
ZnSsdHw0Fw+bgixPg2MQ9k9oefFeqa+7Kqdlz5bbrUYV2volxhDFtnI4Mh8BiWCN
xDH1Hizq+GKCcHsinDZWurCqder/afJBnQs+SBSL6MVApHt+d35zjBD92fO2Je56
dhMfzCgOKXeJ340WhW3TjD1zqLZXeaCyUNRnfOmWZV8nEhtHOFbUCU7r/KkjMZO9
AgMBAAGjgeEwgd4wDgYDVR0PAQH/BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAw
HQYDVR0OBBYEFMDMA0a5WCDMXHJw8+EuyyCm9Wg6MHgGCCsGAQUFBwEBBGwwajAz
BggrBgEFBQcwAYYnaHR0cDovL29jc3Auc3RnLWludC14MS5sZXRzZW5jcnlwdC5v
cmcvMDMGCCsGAQUFBzAChidodHRwOi8vY2VydC5zdGctaW50LXgxLmxldHNlbmNy
eXB0Lm9yZy8wHwYDVR0jBBgwFoAUwSZ0pIpEoOb6ICjYXCOaRYgYeeAwDQYJKoZI
hvcNAQELBQADggIBAHODDwZVaO5EqEYoVvEPPzaZas5BNVRHUAdc+xNg4oKACBAW
o3mnX1tKr9lsWSDxLrCE7y+mdRq37PKzapEaL1q8KYXgzI1Ua7JeyOvCs4IMmhSZ
HLSJMFgAv77nD28kB6teMlJI+NxmvD5cmsDl+1C2D862DFuiy3R/80c++ZIqfWg3
CvsQmwx0bategh3cT8mPwQEdRW0LpgomT37kSxZSGn9TzPXQ+NSvD/CpEF0mVQWM
09aiOE3QWg8BpdzxpbbmEhtWv4MNU1U3iyYNjaPzqD1J3R/7IjJmsNbDY5XKoqIB
AeHPisSzP8CdCwQpJC8rBDefUfrbYqvhWuCff+amrUe01nvp9jtWefwUWWSwcjEg
xYwz2vt6TgLNw5wBWk854x6yc323se/Wp7u7F9lguCRIUMPVH9MfBzR1wyUfpbZa
eFVPFkHQsKv5ydKNQlk8fO97xXhpK4yueMNLnjbWEDKnEvJtCsbqlQm3XHWvqhz9
B/V1c95n8Z9Av2uVZ5HvZKnA9OXi4WF1ES6hkiFzom/exWxBxd+skh6yJuX1edpX
L5TSN5XTa5OPONWh3AQfz7/0aenJNhyPJ4687pwQpGir4ctvT1k3enSRNqO6Vwxv
0BB50f7tpC0k/XzGyQyCVXo6jjDv1057VbZTUB+Y7BzXvcm7aglHPA71K3nW
-----END CERTIFICATE-----
CERT

foreach my $method (qw/csr key cert chain fullchain/) {
    unless ($le->$method->exists) {
        diag "Populating " . $le->$method;
        $le->$method->spew('blabla');
    }
}
$le->live_fullchain->spew($fake_cert);
ok($le->live_cert_names_ok, "All the names are in");
ok $le->live_cert_object->extensions_by_oid->{"2.5.29.17"}->to_string, "Found SAN";
diag $le->live_cert_object->extensions_by_oid->{"2.5.29.17"}->to_string;
diag $le->live_cert_object->subject;
diag "Installing empty certs";
$le->_backup_and_install;
$le->live_fullchain->spew($fake_cert);
ok (path($le->directory)->child($le->now_string)->exists, "Found the backup directory");

ok (defined $le->live_cert_is_valid, "Checked cert: " . $le->live_cert_is_valid);
ok (defined $le->live_cert_expiration_ok, "Expiration: " . $le->live_cert_expiration_ok);

foreach my $method (qw/csr key cert chain fullchain/) {
    my $live = "live_" . $method;
    ok($le->$live->exists, $le->$live . " exists");
}
ok (1, "Reached the end");
