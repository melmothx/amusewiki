#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use JSON::MaybeXS;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use AmuseWikiMeta::Archive::Config;
use Test::More tests => 14;
use Data::Dumper::Concise;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;



{
    my $schema = AmuseWikiFarm::Schema->connect('amuse');
    my $wd = Path::Tiny::tempdir(CLEANUP => 0);
    my $conf = $wd->child("amw-meta-config.yml");
    $ENV{AMW_META_ROOT} = "doc/meta-search";
    my $obj = AmuseWikiMeta::Archive::Config->new(config_file => "$conf",
                                              schema => $schema);

    $obj->generate_config;
    $ENV{AMW_META_CONFIG_FILE} = "$conf";
}


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiMeta');

$mech->get_ok('/search/ajax');
my $data = decode_json($mech->content);
diag Dumper($data);
foreach my $k (qw/matches filters pager/) {
    ok $data->{$k}, "$k found in the json";
}
$mech->get_ok('/');
$mech->content_contains('<!doctype html>', "Static pages served");
$mech->get('/blablabla');
is $mech->status, 404;
$mech->get_ok('/feed');
$mech->get_ok('opensearch.xml');
#diag $mech->content;
# diag $mech->content;
$mech->get_ok('/opds');
$mech->get_ok('/opds/new');
$mech->get_ok('/opds/new/2');
$mech->get_ok('/opds/search?query=pippo');
$mech->get_ok('/opds/search?query=pippo+prova');
path(AmuseWikiMeta::Archive::Config->new(config_file => $ENV{AMW_META_CONFIG_FILE})->stub_database)->remove;

