use strict;
use warnings;
use utf8;
use Test::More tests => 12;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Category;

my ($res, $diag, $host);

$host = { host => 'test.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/authors', $host);
like $res->decoded_content, qr{ĆaoX.*CiaoX.*Cikla}s,
  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$res = request('/topics', $host);
like $res->decoded_content, qr{ŽtopicX.*Zurro}s,
  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$res = request('/topics/miaox', $host);
like $res->decoded_content, qr{<h.>\s*MiaoX\s*</h.>}, "title ok";
like $res->decoded_content, qr{Ža Third test.*Zu A XSecond}s,
  "topic sorting details ok";

$res = request('/authors/caox', $host);
like $res->decoded_content, qr{<h.>\s*ĆaoX\s*</h.>}, "title ok";
like $res->decoded_content, qr{Ža Third test.*Zu A XSecond}s,
  "author sorting details ok";



$host = { host => 'blog.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/authors', $host);
like $res->decoded_content, qr{Ciao.*Cikla.*Ćao}s,
  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

$res = request('/topics', $host);
like $res->decoded_content, qr{Zurro.*Žtopic}s,
  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

$res = request('/topics/ztopic', $host);
like $res->decoded_content, qr{<h.>\s*Žtopic\s*</h.>}, "title ok";
like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
  "topic sorting details ok";

$res = request('/authors/ciao', $host);
like $res->decoded_content, qr{<h.>\s*Ciao\s*</h.>}, "title ok";
like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
  "author sorting details ok";
