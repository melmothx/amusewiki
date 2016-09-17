use strict;
use warnings;
use utf8;
use Test::More tests => 44;
use Date::Parse qw/str2time/;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Library;

my ($res, $diag);
my $host = { host => 'test.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/library', $host);
like $res->decoded_content, qr{Ža Third test};
like $res->decoded_content, qr{Zu A XSecond test}s;

# like $res->decoded_content, qr{Ža Third test.*Zu A XSecond test}s,
#  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

like $res->decoded_content, qr{bootstrap\.amusejournal\.css}, "found custom template";
unlike $res->decoded_content, qr{bootstrap\.amusewiki\.css}, "found layout template";

$res = request('/library/second-test', $host);
ok($res->is_success($res));
ok($res->header('last-modified'), "Found the last modified header");
like $res->header('last-modified'), qr{20\d\d \d\d:\d\d:\d\d}, "Last modified header seems fine";
my $base_time = str2time($res->header('last-modified'));
diag $res->header('last-modified');
ok $base_time, "Timestamp ok";

foreach my $ext (qw/pdf epub tex muse zip/) {
    $res = request('/library/second-test.' . $ext, $host);
    ok($res->is_success);
    ok($res->header('last-modified'), "Found the last modified header");
    diag 'second-test.' . $ext . " has " . $res->header('last-modified');
    like $res->header('last-modified'), qr{20\d\d \d\d:\d\d:\d\d}, "Last modified header seems fine";
    my $file_timestamp = str2time($res->header('last-modified'));
    ok ($file_timestamp, "timestamp ok");
    ok ($file_timestamp >= $base_time, "Generated file has correct timestamp");
}

$res = request('/library/second-test.lt.pdf', $host);
ok(!$res->is_success);


$host = { host => 'blog.amusewiki.org' };
$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/library', $host);
like $res->decoded_content, qr{Zu A Second test}s;
like $res->decoded_content, qr{Ža Third test}s;

# like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
#  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

unlike $res->decoded_content, qr{CUSTOM TEMPLATE}, "custom template not found";
unlike $res->decoded_content, qr{Custom layout}, "custom layout not";

foreach my $i (qw/f-t-cata.jpg f-t-testimage.png/) {
    $res = request("/library/$i", $host);
    ok($res->is_success, "found the image $i");
    like($res->header('content-type'), qr{^image/}, "Content type is image");
}


$res = request('/library/first-test', $host);
like $res->decoded_content, qr{Source: My own work}, "Found source";
like $res->decoded_content, qr{Note: This is just a test}, "Found notes";
