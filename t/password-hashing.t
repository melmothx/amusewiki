#!perl
use strict;
use warnings;
use Test::More tests => 15;
use Authen::Passphrase::BlowfishCrypt;
use Authen::Passphrase::SaltedDigest;

# ensure that we can still login with old mechanism

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};


use AmuseWikiFarm::Schema;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('User')->search({ username => 'gonzo' })->delete;
my $user = $schema->resultset('User')->create({
                                               username => 'gonzo',
                                               password => 'xxxxxxxxxxxxxxx',
                                              });

my $sd_hash = Authen::Passphrase::SaltedDigest->new(salt_random => 20,
                                                    algorithm => "SHA-1",
                                                    passphrase => '123456');
diag $sd_hash->as_rfc2307;

my $bc_hash = Authen::Passphrase::BlowfishCrypt->new(salt_random => 1,
                                                     cost => 13,
                                                     passphrase => '123456');

diag $bc_hash->as_rfc2307;

diag $user->password->as_rfc2307;

ok $user->check_password('xxxxxxxxxxxxxxx');

foreach my $h ($sd_hash, $bc_hash) {
    diag "Hash is " . $h->as_rfc2307;
    $user = $user->get_from_storage;
    $user->set_password_hash($h->as_rfc2307);
    $user = $user->get_from_storage;
    ok !$user->check_password('xxxxxxxxxxxxxxx') or die "Password not changed?";
    ok !$user->check_password();
    ok !$user->check_password('');
    ok $user->check_password('123456'), "Password ok using " . $h->as_rfc2307;
    ok !$user->check_password('!123456');
    ok !$user->check_password($h->as_rfc2307);
    $user = $user->get_from_storage;
    $user->update({ password => 'xxxxxxxxxxxxxxx' });
    ok $user->check_password('xxxxxxxxxxxxxxx');
    $user = $user->get_from_storage;
}


