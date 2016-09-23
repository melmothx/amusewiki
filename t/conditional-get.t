#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use strict;
use warnings;
use Test::More tests => 47;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Schema;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

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

$site->multilanguage('de en es fi fr hr it mk nl pl ru sr sv sq');
$site->update;

{
    my $etag;
    my $url = '/latest';
    my $text;
    for (1..5) {
        $mech->get($url);
        $mech->content_contains('set-language');
        $etag ||= $mech->response->header('ETag');
        is ($etag, $mech->response->header('ETag'));
        $mech->get($url, 'If-None-Match' => $etag);
        is $mech->status, 304, "304 not modified";
    }
}

$site->multilanguage('');
$site->update;

{
    my $etag;
    my $url = '/latest';
    for (1..5) {
        $mech->get($url);
        $etag ||= $mech->response->header('ETag');
        is ($etag, $mech->response->header('ETag'));
        $mech->get($url, 'If-None-Match' => $etag);
        is $mech->status, 304, "304 not modified";
    }
}
