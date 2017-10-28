#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 61;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site fill_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use DateTime;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0paging0');

$site->update({
               multilanguage => 'hr it en es fr nl de',
               secure_site => 0,
              });
              
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my ($user, $pass) = (qw/pagadim pagpass/);
$schema->resultset('User')->search({ username => $user })->delete;
$schema->resultset('User')->create({ username => $user,
                                     password => $pass,
                                     user_sites => [ { site => $site } ],
                                     user_roles => [ { role => { role => 'admin' } } ] });

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => $user, __auth_pass => $pass });
$mech->get_ok('/user/site');
$mech->content_contains('pagination_size');
my %pages = (
             pagination_size => 3,
             pagination_size_latest => 4,
             pagination_size_search => 5,
             pagination_size_monthly => 6,
             pagination_size_category => 7,
            );

$mech->submit_form(with_fields => { %pages },
                   button => 'edit_site');
diag "Populating site";
fill_site($site);

$site->discard_changes;
foreach my $method (keys %pages) {
    is $site->$method, $pages{$method}, "$method set ok";
}
$mech->get_ok('/stats/popular');
is count_items($mech), $pages{pagination_size};
$mech->get_ok('/latest');
is count_items($mech), $pages{pagination_size_latest};
$mech->get_ok('/search?query=exist');
my $now = DateTime->now;
is count_items($mech), $pages{pagination_size_search};
$mech->get_ok('/monthly/' . $now->year . '/'. $now->month);
is count_items($mech), $pages{pagination_size_monthly};

foreach my $cat ($site->categories) {
    $mech->get_ok($cat->full_uri);
    is count_items($mech), $pages{pagination_size_category};
}

$mech->get_ok('/user/site');
$mech->submit_form(with_fields => {
                                   pagination_size => 100,
                                   pagination_size_latest => 100,
                                   pagination_size_search => 100,
                                   pagination_size_monthly => 100,
                                   pagination_size_category => 100,
                                  },
                   button => 'edit_site');

foreach my $i (1..20) {
    $site->create_new_text({ uri => "fill-$i",
                             title => "Fill-$i",
                           }, 'text');
}

foreach my $url ('/stats/popular',
                 '/latest',
                 '/listing',
                 '/search?query=exist',
                 '/monthly/' . $now->year . '/'. $now->month,
                 (map { $_->full_uri } $site->categories)) {
    $mech->get_ok($url);
    $mech->content_contains('amw-listing-item');
    $mech->content_lacks('class="pagination"');
}

$mech->get_ok('/user/site');
$mech->submit_form(with_fields => {
                                   pagination_size => 5,
                                   pagination_size_latest => 5,
                                   pagination_size_search => 5,
                                   pagination_size_monthly => 5,
                                   pagination_size_category => 5,
                                  },
                   button => 'edit_site');

foreach my $i (1..4) {
    $mech->get_ok("/publish/all/$i");
    $mech->content_contains('/library/fill-');
    $mech->content_contains('Created new text');
}


sub count_items {
    my $mech = shift;
    my $content = $mech->content;
    $mech->content_contains('class="pagination"');
    my $count = 0;
    $count++ while $content =~ m/amw-listing-item/g;
    return $count;
}
