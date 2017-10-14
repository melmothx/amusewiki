#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 340;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $sid = '0listing0';
my $site;
# unless ($site = $schema->resultset('Site')->find($sid))
{
    $site = create_site($schema, $sid);
    $site->update({
               secure_site => 0,
               epub => 1,
              });
    foreach my $i (0..9) {
        my $pubdate = DateTime->now->subtract(days => $i + 10)->ymd;
        if ($i == 7) {
            $pubdate = DateTime->now->add(days => $i + 100)->ymd;
        }
        if ($i == 3) {
            $pubdate = DateTime->now->ymd;
        }
        my ($rev) = $site->create_new_text({ uri => "my-title-$i",
                                             title => 'Title #' .  $i,
                                             teaser => ($i % 2 ? "This is the preview for $i" : ''),
                                             author => "Author $i",
                                             pubdate => $pubdate,
                                             lang => 'en' }, 'text');
        if ($i % 2) {
            $rev->edit($rev->muse_body . "\n\n** Test\n\nblabla\n")
        } else {
            $rev->edit($rev->muse_body . "\n\n*** Test\n\nblabla\n")
        }
        $rev->commit_version;
        $rev->publish_text;
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my %expected = (
                pubdate_asc => '/library/my-title-9',
                pubdate_desc => '/library/my-title-3',
                title_asc => '/library/my-title-0',
                title_desc => '/library/my-title-9',
               );


foreach my $login (0..1) {
    foreach my $sorting ($site->titles->available_sortings) {
        diag $sorting->{name};
        my $url = '/listing?sort=' .  $sorting->{name} . '&rows=1';
        $mech->get_ok($url);
        $mech->content_contains($expected{$sorting->{name}}) or die;
        my @pager_links = $mech->find_all_links(url_regex => qr/\/listing/);
        is scalar(@pager_links), 9, "9 links found for the pager";
        foreach my $link ($url, @pager_links) {
            $mech->get_ok($link);
            foreach my $link ($mech->find_all_links(url_regex => qr/\/library\/.+/)) {
                diag $link->url;
            }
        }
        my %all = map { $_->full_uri => 1 } $site->titles;;
        if ($login) {
            $mech->get_ok('/login');
            ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
               "Found login form");
        }
        foreach my $page (1..( 9 + $login )) {
            $mech->get_ok('/listing?sort=' .  $sorting->{name} . '&rows=1&page=' . $page);
            if ($page == 1) {
                $mech->content_like(qr{link rel="next" href=".*/listing\?});
                $mech->content_unlike(qr{link rel="prev" href=".*/listing\?});
            }
            elsif ($page == (9 + $login)) {
                $mech->content_unlike(qr{link rel="next" href=".*/listing\?});
                $mech->content_like(qr{link rel="prev" href=".*/listing\?});
            }
            else {
                $mech->content_like(qr{link rel="next" href=".*/listing\?});
                $mech->content_like(qr{link rel="prev" href=".*/listing\?});
            }
            foreach my $link ($mech->find_all_links(url_regex => qr/\/library\/.+/)) {
                diag "Found " . $link->URI->path;
                delete $all{$link->URI->path};
            }
        }
        unless ($login) {
            ok $all{'/library/my-title-7'}, "Deferred is excluded";
            delete $all{'/library/my-title-7'};
        }
        ok(!%all, "All links found") or diag Dumper(\%all);
        if ($login) {
            $mech->get_ok('/logout');
        }
    }
}
