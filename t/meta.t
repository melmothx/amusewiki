#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{AMW_META_ROOT} = "doc/meta-search";
};
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More;
use Data::Dumper::Concise;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiMeta');

$mech->get_ok('/search');
my $data = from_json($mech->content);
ok $data;

diag Dumper($data);

$mech->get_ok('/');
$mech->content_contains('<!doctype html>', "Static pages served");

$mech->get('/blablabla');
is $mech->status, 404;

done_testing;
