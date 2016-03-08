use strict;
use warnings;
use Test::More tests => 15;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Catalyst::Test 'AmuseWikiFarm';
use Test::WWW::Mechanize::Catalyst;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
my $text = $site->titles->first;
foreach my $lang (sort keys (%{ $site->known_langs })) {
    ok($text->pubdate_locale($lang), "$lang: " . $text->pubdate_locale($lang));
}
$mech->get_ok('/latest');
$mech->get_ok('/latest/2');
