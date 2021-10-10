use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 33;

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use Data::Dumper;

use AmuseWikiFarm::Schema;
use Encode;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
ok ($site, "Found the site");
$site->categories->search({ uri => 'empty-category' })->delete;
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

$mech->get_ok("/api/ckeditor");
my $config = from_json($mech->response->content);
diag Dumper($config);
is $config->{language}, "hr";
is $config->{toolbar}, "AmuseWiki";
ok $config->{toolbar_AmuseWiki};

$empty->delete;

$mech->get_ok("/api/autocompletion/adisplay");
my $adisplays = from_json($mech->content);
ok @$adisplays == 3;
ok scalar(grep { $_ eq 'Marco & C.' }  @$adisplays);
diag $mech->content;
is_deeply($adisplays, $site->titles->list_display_authors);

$mech->get_ok("/api/datatables-lang?__language=ru");
$mech->content_contains(encode('UTF-8', 'активировать'));
$mech->get_ok("/api/datatables-lang?__language=hr");
$mech->content_contains(encode('UTF-8', 'Prikaži'));
$mech->get_ok("/api/datatables-lang?__language=en");
$mech->content_contains('Showing');
$mech->get_ok("/api/latest");
$mech->content_contains(q{"category_id"});
$mech->content_contains(q{"title_categories"});
