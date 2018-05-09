#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
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

$mech->get_ok('/');
my $data = from_json($mech->content);
ok $data;

done_testing;
