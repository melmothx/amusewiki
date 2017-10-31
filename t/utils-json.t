#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 8;
use AmuseWikiFarm::Utils::Amuse qw/to_json from_json/;
use Data::Dumper;

my $data = {
            'òàèùšć' => [ 'òàèùšć'],
           };

{
    my $json = to_json($data);
    ok $json;
    # diag $json;
    like $json, qr/\\u00/;
    my $back_data = from_json($json);
    is_deeply($back_data, $data) or diag Dumper($data);
}
{
    my $json = to_json($data, ascii => 0, pretty => 1, canonical => 1);
    ok $json;
    # diag $json;
    unlike $json, qr/\\u00/;
    like $json, qr{òàèùšć}, "Found string";
    like $json, qr{\n}, "Found newline";
    my $back_data = from_json($json);
    is_deeply($back_data, $data) or diag Dumper($data);
}
