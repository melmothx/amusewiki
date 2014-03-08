use strict;
use warnings;
use utf8;
use Test::More tests => 19;
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

like $res->decoded_content, qr{CUSTOM TEMPLATE}, "found custom template";
like $res->decoded_content, qr{Custom layout}, "found layout template";

$res = request('/library/second-test', $host);
ok($res->is_success($res));

foreach my $ext (qw/pdf epub tex muse zip/) {
    $res = request('/library/second-test.' . $ext, $host);
    ok($res->is_success);
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

$res = request('/library/cata.jpg', $host);
ok($res->is_success, "found the image");
is($res->header('content-type'), 'image/jpeg', "Content type is correct");

$res = request('/library/first-test', $host);
like $res->decoded_content, qr{Source: My own work}, "Found source";
like $res->decoded_content, qr{Note: This is just a test}, "Found notes";
