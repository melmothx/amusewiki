#!perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Data::Dumper;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;


use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my @others = $site->other_sites;
is (scalar(@others), 1, "Found a related site");

my $lonely = create_site($schema, '0multi0');
print Dumper($lonely->sitegroup);
@others = $lonely->other_sites;
ok (!@others, "No others site found for multi");
