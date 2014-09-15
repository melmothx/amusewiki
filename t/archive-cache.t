#!perl

use strict;
use warnings;

# let's use the blog's data

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Cache;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 10;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $cache = AmuseWikiFarm::Archive::Cache->new;

ok($cache->cache_dir, "Found the cache dir") and diag $cache->cache_dir;

$cache->clear_all;

foreach my $path ('/library', '/topics', '/authors') {
    $mech->get_ok($path);
    my $content = $mech->content;
    $mech->get_ok($path);
    is $mech->content, $content;
}

my $rs = $site->titles->published_specials;


