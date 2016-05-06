#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 33;
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
    $titles{$title->full_uri} = $total;
}
diag Dumper(\%titles);
$schema->resultset('TitleStat')->delete_old;

$mech->get_ok('/stats/popular');
foreach my $uri (keys %titles) {
    my $count = $titles{$uri};
    $mech->content_like(qr{\Q$uri\E.*?>\Q$count\E<}s);
}

$schema->resultset('TitleStat')->search({})->delete;
foreach my $uri (keys %titles) {
    $mech->get_ok($uri);
}
is $schema->resultset('TitleStat')->count, 0;

# this is puzzling. Without this innocent request, we're losing the
# session. Looks like a mech bug, but who knows?
$mech->get_ok('/');
diag $mech->uri;

foreach my $uri (keys %titles) {
    $mech->get_ok($uri . '.html');
    ok($mech->response->header('Set-Cookie'), "Cookie set on " . $mech->uri->path);
    diag "request with cookie:" . $mech->response->request->header('Cookie');
    diag $mech->response->header('Set-Cookie');
}

is $schema->resultset('TitleStat')->count, scalar(keys %titles), "First access added records";

foreach my $uri (keys %titles) {
    $mech->get_ok($uri . '.epub');
    ok $mech->response->request->header('Cookie'), "Cookie sent";
    diag "request with cookie:" . $mech->response->request->header('Cookie');
    diag $mech->response->header('Set-Cookie');
}
is $schema->resultset('TitleStat')->count, scalar(keys %titles), "Nothing added at second access";

$mech->get_ok('/bookbuilder/');
$mech->form_with_fields('answer');
$mech->field(answer => 'January');
$mech->click;

foreach my $uri (keys %titles) {
    $uri =~ s/library/bookbuilder\/add/;
    $mech->get_ok("$uri");
}
is $schema->resultset('TitleStat')->count, scalar(keys %titles) * 2, "BB added at second access";

my $robot = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                agent => 'Googlebot/2.1 (+http://www.google.com/bot.html)',
                                                host => $site->canonical);

$robot->get_ok('/');
foreach my $uri (keys %titles) {
    $robot->get_ok($uri . '.epub');
}
is $schema->resultset('TitleStat')->count, scalar(keys %titles) * 2, "Nothing added from bots";

