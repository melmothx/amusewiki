use strict;
use warnings;
use utf8;
use Test::More tests => 3;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Category;

ok( request('/category')->is_success, 'Request should succeed' );

my ($res, $diag, $host);

$host = { host => 'test.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/authors', $host);
like $res->decoded_content, qr{ĆaoX.*CiaoX.*Cikla}s,
  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$host = { host => 'blog.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/authors', $host);
like $res->decoded_content, qr{Ciao.*Cikla.*Ćao}s,
  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";




done_testing();
