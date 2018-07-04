#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use strict;
use warnings;
use Path::Tiny;
use AmuseWikiMeta::Archive::Config;
use AmuseWikiFarm::Schema;
use Test::More tests => 7;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $wd = Path::Tiny::tempdir(CLEANUP => 0);
my $conf = $wd->child("amw-meta-config.yml");

$ENV{AMW_META_ROOT} = "$wd";

my $obj = AmuseWikiMeta::Archive::Config->new(config_file => "$conf",
                                              schema => $schema);

$obj->generate_config;


ok (-f $obj->stub_database, $obj->stub_database . ' is created');

ok (-f $conf);

foreach my $method (qw/root_directory site_list site_map languages_map hostnames_map/) {
    ok $obj->$method, "$method ok" and diag Dumper($obj->$method);
}
