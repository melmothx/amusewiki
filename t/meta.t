#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{AMW_META_ROOT} = "doc/meta-search";
    $ENV{AMW_META_XAPIAN_DB} = "t/xapian.stub";
};
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use JSON::MaybeXS;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 7;
use Data::Dumper::Concise;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;

my $stub = path($ENV{AMW_META_XAPIAN_DB});
my $schema = AmuseWikiFarm::Schema->connect('amuse');
$stub->spew(join("\n",
                 map { "auto " . path($_->xapian->xapian_dir)->absolute }
                 $schema->resultset('Site')->public_only) . "\n");
diag $stub->slurp;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiMeta');

$mech->get_ok('/search');
my $data = decode_json($mech->content);
diag Dumper($data);
foreach my $k (qw/matches filters pager/) {
    ok $data->{$k}, "$k found in the json";
}
$mech->get_ok('/');
$mech->content_contains('<!doctype html>', "Static pages served");
$mech->get('/blablabla');
is $mech->status, 404;
$stub->remove;
