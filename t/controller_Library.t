use strict;
use warnings;
use utf8;
use Test::More tests => 3;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Library;

ok( request('/library')->is_success, 'Request should succeed' );

my ($res, $diag);
my $host = { host => 'test.amusewiki.org' };

$diag = request('/admin/debug_site_id')->decoded_content;
$res = request('/library', $host);
like $res->decoded_content, qr{Ža Third test.*Zu A XSecond test}s,
  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$host = { host => 'blog.amusewiki.org' };
$diag = request('/admin/debug_site_id')->decoded_content;
$res = request('/library', $host);
like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

