#!perl

use strict;
use warnings;
use utf8;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0sr0');
my @langs = sort keys %{ $site->known_langs };

plan tests => scalar(@langs) + 1;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

# given that the model is persitent (like the db), a failure here is
# going to make the whole circus crash randomly.
$site->update({ locale => 'sr' });
    $mech->get_ok('/', "sr is fine (or kind of)");

foreach my $lang (@langs) {
    $site->update({ locale => $lang });
    $mech->get_ok('/', "$lang is fine");
}


