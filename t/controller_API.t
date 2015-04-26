use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 16;

use Test::WWW::Mechanize::Catalyst;
use JSON qw/from_json/;
use Data::Dumper;

use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
ok ($site, "Found the site");
my $empty = $site->categories->create({
                                       name => 'empty category',
                                       uri => 'empty-category',
                                       type => 'topic',
                                      });
$empty->discard_changes;
is ($empty->text_count, 0);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
foreach my $target (qw/sorttopics listtopics listauthors authors author topic/) {
    $mech->get_ok("/api/autocompletion/$target");
    my $data = from_json($mech->response->content);
    ok (scalar(@$data), Dumper($data));
}

$mech->get_ok("/api/autocompletion/topic");
my $topics = from_json($mech->response->content);
my @empty = grep { $_ eq 'empty category' } @$topics;
ok (!@empty, "No empty categories found") or diag Dumper($topics);

$empty->delete;
