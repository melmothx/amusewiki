#!perl

use strict;
use warnings;
use utf8;
use Path::Tiny;
use File::Spec::Functions qw/catdir/;
use Test::More tests => 15;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0inc0');

foreach my $d ({
                sorting_pos => 0,
                directory => $site->repo_root,
               },
               {
                sorting_pos => 1,
                directory => path('t')->absolute,
               }) {
    $site->add_to_include_paths($d);
}

is_deeply $site->amuse_include_paths, [ $site->repo_root, path('t')->absolute ];
