#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;
use Data::Dumper;
use Cache::FastMmap;

my $f = File::Spec->rel2abs(File::Spec->catfile(qw/opt cache fastmmap/));
my $c = Cache::FastMmap->new(raw_values => 0,
                             unlink_on_exit => 0,
                             init_file => 0,
                             cache_size => '100m',
                             share_file => File::Spec->rel2abs(File::Spec->catfile(qw/opt cache fastmmap/)));
print Dumper([sort $c->get_keys(0)]);
