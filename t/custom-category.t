#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 77;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

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
                                       }, "text");
    my $preamble =<<"EOF";
#publisher Pinco $i, Pallino $i
#location Washington, DC; Zagreb, Croatia; 東京, Japan;
#season summer $i my'"&"'<stuff>
EOF
    $rev->edit($preamble . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->count;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
foreach my $c ($site->categories) {
    diag join(' ', $c->type, $c->uri, $c->name, $c->titles->count);
    $mech->get_ok($c->full_uri);
    $mech->get($c->full_uri . '?bare=1');
    foreach my $title ($c->titles) {
        my $url = $title->full_uri;
        $mech->content_contains($title->full_uri, "Found $url in " . $c->full_uri);
    }
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
