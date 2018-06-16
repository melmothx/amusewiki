#!/usr/bin/env perl

BEGIN { die "Do not run this as root" unless $>; }

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use AmuseWikiMeta::Archive::Config;
use Path::Tiny;
use YAML qw/DumpFile/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $wd = Path::Tiny->tempdir(CLEANUP => 0);
my $out = $wd->child('amw-meta-config.yml');

my $conf = AmuseWikiMeta::Archive::Config->new(config_file => "$out",
                                               schema => $schema)->generate_config;
print "Configuration file left in $out\n";

