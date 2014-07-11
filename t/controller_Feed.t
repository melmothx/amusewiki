use strict;
use warnings;
use Test::More tests => 12;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use utf8;

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Feed;

foreach my $host ({ host => 'test.amusewiki.org' },
                  { host => 'blog.amusewiki.org' }) {
    my $request = request('/feed', $host);

    ok( $request->is_success, 'Request should succeed' );

    like $request->decoded_content, qr/\Q$host->{host}\E/;
    is $request->content_type, 'application/rss+xml';
    like $request->decoded_content, qr/<enclosure.*epub/;
}

{
    my $request = request('/feed', { host => 'blog.amusewiki.org' });
    diag "Testing encoding";
    my $content = $request->decoded_content;
    like $content, qr/Ža Third test/;
    like $content, qr/Marco &amp;amp; C./;
    like $content, qr/isPermaLink="true"/;
    like $content, qr[library/first-test.epub];
}

