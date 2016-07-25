#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 2;
use File::Spec::Functions qw/catfile catdir/;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0sr0');
$site->update({ locale => 'sr' });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');

