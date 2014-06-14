use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 12;

use Test::WWW::Mechanize::Catalyst;
use JSON qw/from_json/;
use Data::Dumper;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');
foreach my $target (qw/sorttopics listtopics listauthors authors author topic/) {
    $mech->get_ok("/api/autocompletion/$target");
    my $data = from_json($mech->response->content);
    ok (@$data, Dumper($data));
}


