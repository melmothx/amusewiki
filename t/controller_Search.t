use strict;
use warnings;
use Test::More tests => 4;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };



use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Search;

my $host = { host => 'blog.amusewiki.org' };

my $res = request('/search?query=a', $host);
ok ($res->is_success);

like $res->decoded_content, qr/second-test/, "Found a text";

$res = request('/search?query=a&complex_query=1&title=My first test&fmt=json',
               $host);
like $res->decoded_content, qr/first-test/, "Found the text";
unlike $res->decoded_content, qr/second-test/, "Other title filtered out";
