use strict;
use warnings;
use utf8;
use Test::More tests => 46;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Controller::Category;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0test0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my ($res, $diag, $host);

$mech->get_ok('/category/author');

foreach my $str (qw/ĆaoX CiaoX Cikla/) {
    $mech->content_contains($str);
}

$mech->content_like(qr{ĆaoX.*CiaoX.*Cikla}si,
                    "sorting with Ž and Z is diacritics-insensitive for code locale " . $site->locale);

$mech->get_ok('/category/topic');

$mech->content_like(qr{ŽtopicX.*Zurro}si,
                    "sorting with Ž and Z is diacritics-insensitive for code locale " . $site->locale);


$mech->get_ok('/category/author/caox');
$mech->content_contains('<span id="amw-category-details-category-name">ĆaoX</span>');
$mech->content_like(qr{Ža Third test.*Zu A XSecond}s);


$mech->get_ok('/category/topic/miaox');
$mech->content_contains('<span id="amw-category-details-category-name">MiaoX</span>');
$mech->content_like(qr{Ža Third test.*Zu A XSecond}s);


# set the locale to HR
$site->update({ locale => 'hr'  });
$site->collation_index;


$mech->get_ok('/category/author');
$mech->content_like(qr{CiaoX.*Cikla.*ĆaoX.*}si,
                    "sorting with Ž and Z is diacritics-sensitive for code locale " . $site->locale);

$mech->get_ok('/category/topic');
$mech->content_like(qr{Zurro.*ŽtopicX.*}si,
                    "sorting with Ž and Z is diacritics-sensitive for code locale " . $site->locale);



$mech->get_ok('/category/author/caox');
$mech->content_contains('<span id="amw-category-details-category-name">ĆaoX</span>');
$mech->content_like(qr{Zu A XSecond.*Ža Third test.*}s);


$mech->get_ok('/category/topic/miaox');
$mech->content_contains('<span id="amw-category-details-category-name">MiaoX</span>');
$mech->content_like(qr{Zu A XSecond.*Ža Third test.*}s);

# reset to EN
$site->update({ locale => 'en' });
$site->collation_index;

$site = $schema->resultset('Site')->find('0blog0');
$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => $site->canonical,
                                            max_redirect => 0,
                                           );

diag "Testing legacy paths";
foreach my $path ('/authors/ciao',
                   '/topics/ztopic',
                   '/topics',
                   '/authors',
                   # non existent, but redirection works
                   '/topics/xyz',
                   '/authors/xyz') {
    $mech->get($path);
    is $mech->status, 301, "$path is moved permanentently";
    my $expected = $path;
    $expected =~ s!/?(topic|author)s!/category/$1!;
    diag Dumper($mech->response->header('location'));
    is $mech->response->header('location'), $site->canonical_url . $expected,
      "Requesting $path lead to permanent redirect";
    $mech->content_contains('This item has moved');
}


my $newcat = $site->categories->update_or_create({
                                                  name => 'This cat is not active',
                                                  type => 'topic',
                                                  uri => 'this-cat-is-not-active',
                                                 });

$newcat->discard_changes;

$mech->get('/category/topic/this-cat-is-not-active');
is($mech->status, '404', 'Inactive cat not found');

$mech->get('/category/topic');
$mech->content_lacks('this-cat-is-not-active',
                     "Inactive cat is not listed");

my @all_topics = $site->categories->by_type('topic');
my @active_topics = $site->categories->active_only_by_type('topic');

ok(scalar(@all_topics));
ok(scalar(@active_topics));

ok(@all_topics > @active_topics, "filtering by active works");

$newcat->delete;
