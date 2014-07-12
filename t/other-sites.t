#!perl
use strict;
use warnings;
use Test::More tests => 1;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my @others = $site->other_sites;
is (scalar(@others), 1, "Found a related site");

