#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 117;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cc0';

my $site = create_site($schema, $site_id);
is $site->site_category_types->count, 2;
# check if it dies;
$site->init_category_types;

foreach my $ctype ({
                    category_type => 'publisher',
                    active => 1,
                    priority => 2,
                    name_singular => 'Publisher',
                    name_plural => 'Publishers',
                   },
                   {
                    category_type => 'location',
                    active => 1,
                    priority => 3,
                    name_singular => 'Location',
                    name_plural => 'Locations',
                   },
                   {
                    category_type => 'season',
                    active => 1,
                    priority => 4,
                    name_singular => 'Season',
                    name_plural => 'Seasons',
                   }) {
    $site->site_category_types->find_or_create($ctype);
}
$site->discard_changes;
is $site->site_category_types->count, 5;

foreach my $i (1..3) {
    my ($rev) = $site->create_new_text({
                                        title => "$i Hello $i",
                                        textbody => 'Hey',
                                        publisher => "Pinco $i, Pallino $i",
                                        location => "Washington, DC; Zagreb, Croatia; 東京, Japan;",
                                        season => q{summer $i my'"&"'<stuff>"},
                                       }, "text");
    diag $rev->muse_body;
    like $rev->muse_body, qr{#publisher Pinco};
    like $rev->muse_body, qr{#location Wash};
    like $rev->muse_body, qr{#season summer};
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->count;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/action/text/new');
$mech->content_contains('name="location"');
$mech->content_contains('name="publisher"');
$mech->content_contains('name="season"');
foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get_ok($c->full_uri);
    $mech->get($c->full_uri . '?bare=1');
    foreach my $title ($c->titles) {
        my $url = $title->full_uri;
        $mech->content_contains($title->full_uri, "Found $url in " . $c->full_uri);
    }
}

foreach my $ct (qw/location publisher season/) {
    $mech->get_ok("/api/autocompletion/$ct");
    my $data = from_json($mech->response->content);
    ok (scalar(@$data), Dumper($data));
}

$site->site_category_types->update({ active => 0 });

foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get($c->full_uri);
    is $mech->status, 404;
}

$site->site_category_types->update({ active => 1 });

foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get_ok($c->full_uri);
}

foreach my $t ($site->titles) {
    $mech->get_ok($t->full_uri);
    foreach my $c ($t->categories) {
        $mech->content_contains($c->full_uri);
    }
}

ok $site->edit_category_types_from_params({
                                           create => 'pippo',
                                           publisher_active => 0,
                                           publisher_priority => 4,
                                           publisher_name_singular => 'P',
                                           publisher_name_plural => 'PP',
                                          });
{
    my $cc = $site->site_category_types->find({ category_type => 'pippo' });
    ok $cc;
    ok $cc->active;
    is $cc->name_plural, 'Pippos';
    is $cc->name_singular, 'Pippo';

}
{
    my $cc = $site->site_category_types->find({ category_type => 'publisher' });
    ok $cc;
    ok !$cc->active;
    is $cc->name_plural, 'PP';
    is $cc->name_singular, 'P';
}

{
    $site = $site->get_from_storage;
    diag Dumper($site->custom_category_types);
}

foreach my $cat ($site->categories) {
    diag $cat->name . ' ' . $cat->full_uri;
}

foreach my $text ($site->titles) {
    foreach my $header ($text->muse_headers) {
        diag $header->muse_header;
        ok $header->as_html;
        diag $header->as_html;
    }
}
