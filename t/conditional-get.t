#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use strict;
use warnings;
use Test::More tests => 22;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

foreach my $url ('/special/index', '/special/index.html') {
    $mech->get_ok($url);
    my $etag = $mech->response->header('ETag');
    my $lm = $mech->response->header('Last-Modified');
    ok ($etag, "Etag present: $etag");
    ok ($lm, "Last modified present: $lm");
    # both
    $mech->get($url, 'If-None-Match' => $etag, 'If-Modified-Since' => $lm);
    is $mech->status, 304, "304 not modified";
# This is unclear. We provide both, the client should send both.
#     # etag
#     $mech->get($url, 'If-None-Match' => $etag);
#     is $mech->status, 304, "304 not modified";
#     # last modified
#     $mech->get($url, 'If-Modified-Since' => $lm);
#     is $mech->status, 304, "304 not modified";
    $mech->get($url, 'If-None-Match' => $etag . 'x');
    is $mech->status, 200, "refetched";
    $mech->get($url, 'If-None-Match' => undef);
    is $mech->status, 200, "refetched";
    $mech->get($url, 'If-Modified-Since' => $lm . 'x');
    is $mech->status, 200, "refetched";
    $mech->get($url, 'If-Modified-Since' => undef);
    is $mech->status, 200, "refetched";
    $mech->get($url, 'If-Modified-Since' => $lm . 'x', ETag => $etag);
    is $mech->status, 200, "refetched on last modified mismatch";
    $mech->get($url, 'If-Modified-Since' => $lm, ETag => $etag . 'x');
    is $mech->status, 200, "refetched on etag mismatch";
    $mech->get($url, 'If-Modified-Since' => $lm . 'x', ETag => $etag . 'x');
    is $mech->status, 200, "refetched on both mismatch";


}
