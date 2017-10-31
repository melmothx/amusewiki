#!/usr/bin/env perl

BEGIN { die "Do not run this as root" unless $>; }

use strict;
use warnings;
use utf8;
use AmuseWikiFarm::Schema;
use DBIx::Class::Visualizer;

my $schema = AmuseWikiFarm::Schema->connect('amuse');


DBIx::Class::Visualizer->new(schema => $schema)->run(output_file => 'amusewiki-schema.png', format => 'png');
