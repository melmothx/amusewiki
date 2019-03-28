#!perl
use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 35;
use Data::Dumper;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0rss0');
$site->update({ epub => 1 });

ok !$site->rss_feed_file->exists;

ok $site->create_feed;

my $muse = <<'MUSE';

* This is a part

* This is a chapter

FULL TEXT HERE
MUSE
foreach my $num (1..2) {
    foreach my $type (qw/special text/) {
        my ($rev) = $site->create_new_text({
                                            uri => "test-$type-$num",
                                            title => "Ža Third & *test* **$type** <sup>$num</sup>",
                                            author => "Marco & C.",
                                            (
                                             $type eq 'special' ? () :
                                             (teaser => "Teaser *with* *$type* <sup>$num</sup>")
                                            ),
                                            pubdate => DateTime->now->subtract(days => $num)->ymd,
                                           }, $type);
        $rev->edit($rev->muse_body . $muse);
        $rev->commit_version;
        $rev->publish_text;
    }
}

ok $site->create_feed;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $path ('/feed', 'rss.xml') {
    $mech->get_ok($path);
    $mech->content_contains($site->canonical);
    is $mech->content_type, 'application/rss+xml';
    $mech->content_like(qr/<enclosure.*epub/);
    diag "Testing encoding";
    $mech->content_like( qr/<title>Marco &amp; C. - Ža Third &amp; test/);
    $mech->content_like( qr/Marco &amp;amp; C./);
    $mech->content_like( qr/isPermaLink="true"/);
    $mech->content_like( qr[library/test-text-1\.epub]);
    $mech->content_like( qr{library/test-text-2\?v=\d+});
    $mech->content_like( qr{special/test-special-1\?v=\d+});
    is $mech->response->header('Access-Control-Allow-Origin'), '*';
    diag $mech->content;
    $mech->content_lacks('tableofcontentline');
}
$mech->get_ok('/');
ok !$mech->response->header('Access-Control-Allow-Origin');

$site->update({ mode => 'private' });
$mech->get('/feed');
ok $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, 200;
is $mech->uri, 'https://0rss0.amusewiki.org/feed';
$mech->content_contains("<channel>");
ok !$mech->response->header('Access-Control-Allow-Origin');

ok $site->rss_feed_file->exists;
