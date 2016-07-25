#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 3;
use AmuseWikiFarm::Utils::Amuse qw/to_json from_json/;
use Data::Dumper;

my $data = {
            'òàèùšć' => [ 'òàèùšć'],
           };

my $json = to_json($data);
ok $json;
# diag $json;
like $json, qr/\\u00/;
my $back_data = from_json($json);
is_deeply($back_data, $data) or diag Dumper($data);

