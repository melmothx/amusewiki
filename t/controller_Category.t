use strict;
use warnings;
use utf8;
use Test::More tests => 40;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Controller::Category;
use Data::Dumper;

my ($res, $diag, $host);

$host = { host => 'test.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/category/author', $host);

like $res->decoded_content, qr{ĆaoX};
like $res->decoded_content, qr{CiaoX};
like $res->decoded_content, qr{Cikla};
# like $res->decoded_content, qr{ĆaoX.*CiaoX.*Cikla}s,
#   "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$res = request('/category/topic', $host);
like $res->decoded_content, qr{ŽtopicX};
like $res->decoded_content, qr{Zurro}s,
# like $res->decoded_content, qr{ŽtopicX.*Zurro}s,
#  "sorting with Ž and Z is diacritics-insensitive for code locale: $diag";

$res = request('/category/topic/miaox', $host);
like $res->decoded_content, qr{<h.>\s*MiaoX\s*</h.>}, "title ok";
# like $res->decoded_content, qr{Ža Third test.*Zu A XSecond}s,
#  "topic sorting details ok";

like $res->decoded_content, qr{Ža Third test};
like $res->decoded_content, qr{Zu A XSecond};


$res = request('/category/author/caox', $host);
like $res->decoded_content, qr{<h.>\s*ĆaoX\s*</h.>}, "title ok";

# like $res->decoded_content, qr{Ža Third test.*Zu A XSecond}s,
#  "author sorting details ok";
$res->decoded_content, qr{Ža Third test};
$res->decoded_content, qr{Zu A XSecond};


$host = { host => 'blog.amusewiki.org' };

$diag = request('/admin/debug_site_id', $host)->decoded_content;
$res = request('/category/author', $host);
like $res->decoded_content, qr{Ciao};
like $res->decoded_content, qr{Cikla};
like $res->decoded_content, qr{Ćao};
# like $res->decoded_content, qr{Ciao.*Cikla.*Ćao}s,
#   "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

$res = request('/category/topic', $host);
like $res->decoded_content, qr{Zurro.*Žtopic}s,
  "sorting with Ž and Z is diacritics-sensitive for code locale: $diag";

$res = request('/category/topic/ztopic', $host);
like $res->decoded_content, qr{<h.>\s*Žtopic\s*</h.>}, "title ok";
like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
  "topic sorting details ok";

$res = request('/category/author/ciao', $host);
like $res->decoded_content, qr{<h.>\s*Ciao\s*</h.>}, "title ok";
like $res->decoded_content, qr{Zu A Second test.*Ža Third test}s,
  "author sorting details ok";

diag "Testing legacy paths";
foreach my $path ('/authors/ciao',
                   '/topics/ztopic',
                   '/topics',
                   '/authors',
                   # non existent, but redirection works
                   '/topics/xyz',
                   '/authors/xyz') {
    $res = request($path, $host);
    is $res->code, '301', "Requesting $path lead to permanent redirect";
    my $expected = 'http://' . $host->{host} . $path;
    $expected =~ s!/(topic|author)s!/category/$1!;
    is $res->header('location'), $expected, "Redirect to location $expected";
    is $res->message, 'Moved Permanently', "Message is " . $res->message;
}


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find({ canonical => $host->{host} });

my $newcat = $site->categories->update_or_create({
                                                  name => 'This cat is not active',
                                                  type => 'topic',
                                                  uri => 'this-cat-is-not-active',
                                                 });

$newcat->discard_changes;

diag $host->{host};

$res = request('/category/topic/this-cat-is-not-active', $host);
is($res->code, '404', 'Inactive cat not found') or diag $res->decoded_content;

$res = request('/category/topic', $host);
unlike($res->decoded_content, qr/this-cat-is-not-active/,
       "Inactive cat is not listed") or diag $res->decoded_content;

my @all_topics = $site->categories->by_type('topic');
my @active_topics = $site->categories->active_only_by_type('topic');

ok(scalar(@all_topics));
ok(scalar(@active_topics));

ok(@all_topics > @active_topics, "filtering by active works");

$newcat->delete;
