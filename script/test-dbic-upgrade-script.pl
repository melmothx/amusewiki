#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $file = $ARGV[0];
die "first argument must be a file" unless $file && -f $file;

my $sub = do "./$file" or die($@ || $!);

$sub->($schema);


