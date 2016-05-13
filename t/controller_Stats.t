#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 51;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use DateTime;

# we use the existing site

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.8.0',
                                               host => $site->canonical);

# add some stats
$schema->resultset('TitleStat')->delete;

my %titles;

foreach my $title ($site->titles->published_texts) {
    my $guard = $schema->txn_scope_guard;
    $title->title_stats->delete;
    my $total = length($title->uri);
    for (my $i = 0; $i < $total; $i++) {
        $title->add_to_title_stats({
                                    site_id => $site->id,
                                    accessed => DateTime->now->subtract(hours => $i),
                                   });
    }
    $guard->commit;
    $titles{$title->full_uri} = {
                                 count => $total,
                                 id => $title->id,
                                };
}
diag Dumper(\%titles);
$schema->resultset('TitleStat')->delete_old;

$mech->get_ok('/stats/popular');
foreach my $uri (keys %titles) {
    my $count = $titles{$uri}->{count};
    $mech->content_like(qr{\Q$uri\E.*?>\Q$count\E<}s);
}

$schema->resultset('TitleStat')->search({})->delete;
foreach my $uri (keys %titles) {
    $mech->get_ok($uri);
}
is $schema->resultset('TitleStat')->count, 0, "No stats so far";

# this is puzzling. Without this innocent request, we're losing the
# session. Looks like a mech bug, but who knows?

foreach my $uri (keys %titles) {
    $mech->post('/stats/register',  {
                                     id => $titles{$uri}->{id},
                                     type => 'download',
                                    });
    is $mech->status, '200';
    ok(!$mech->response->header('Set-Cookie'), "Cookie not set on " . $mech->uri->path);
    $mech->content_is('OK');
}

is $schema->resultset('TitleStat')->count, scalar(keys %titles), "First access added records";

foreach my $rand (999 .. 1001) {
    foreach my $type (qw/download bookbuilder/) {
        $mech->post('/stats/register',  {
                                         id => $rand,
                                         type => $type,
                                        });
        is $mech->status, '200';
        ok(!$mech->response->header('Set-Cookie'), "Cookie not set on " . $mech->uri->path);
        $mech->content_is('Text not found');
    }
}
is $schema->resultset('TitleStat')->count, scalar(keys %titles),
  "Non-existent ids add no record";

foreach my $uri (keys %titles) {
    $mech->post('/stats/register',  {
                                     id => $titles{$uri}->{id},
                                     type => 'bookbuilder',
                                    });
    is $mech->status, '200';
}
is $schema->resultset('TitleStat')->count, scalar(keys %titles) * 2, "BB added at second access";

foreach my $ua ('Mozilla/5.0 (iPhone; CPU iPhone OS 7_0 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11A465 Safari/9537.53 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
                'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)') {
    my $robot = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    agent => $ua,
                                                    host => $site->canonical);
    $robot->get_ok('/');
    foreach my $uri (keys %titles) {
        $robot->post('/stats/register',  {
                                          id => $titles{$uri}->{id},
                                          type => 'bookbuilder',
                                         });
        is $robot->status, '200';
    }
    is $schema->resultset('TitleStat')->count, scalar(keys %titles) * 2, "Nothing added from $ua";
}
