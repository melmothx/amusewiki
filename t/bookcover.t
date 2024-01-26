#!perl

use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
use Test::More;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

my $schema = AmuseWikiFarm::Schema->connect('amuse');
# use the 0blog0 here.

my $site = $schema->resultset('Site')->find('0blog0');
my $user = $schema->resultset('User')->find({ username => 'root' });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
my $now = DateTime->now(time_zone => 'UTC');

my $anon_bc = $site->bookcovers->create({
                                         created => $now,
                                        });
ok $anon_bc;

my $user_bc = $site->bookcovers->create({
                                         user => $user,
                                         created => $now,
                                        });

ok $user_bc;
done_testing;
