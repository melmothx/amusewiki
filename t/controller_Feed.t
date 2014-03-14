use strict;
use warnings;
use Test::More tests => 9;
use utf8;

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Feed;

foreach my $host ({ host => 'test.amusewiki.org' },
                  { host => 'blog.amusewiki.org' }) {
    my $request = request('/feed', $host);

    ok( $request->is_success, 'Request should succeed' );

    like $request->decoded_content, qr/\Q$host->{host}\E/;
    is $request->content_type, 'application/rss+xml';
}

my $request = request('/feed', { host => 'blog.amusewiki.org' });
diag "Testing encoding";
like $request->decoded_content, qr/Ža Third test/;
like $request->decoded_content, qr/Marco &amp;amp; C./;
like $request->decoded_content, qr/isPermaLink="true"/;

