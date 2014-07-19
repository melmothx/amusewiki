#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Cwd;
use File::Spec::Functions qw/catdir catfile/;


BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $init = catfile(getcwd(), qw/script jobber.pl/);

ok(system($init, 'stop') == 0);

