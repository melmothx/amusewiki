#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 4;
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

$schema->resultset('TitleStat')->delete_old;

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

$mech->get_ok('/stats/popular');
foreach my $uri (keys %titles) {
    my $count = $titles{$uri};
    $mech->content_like(qr{\Q$uri\E.*?>\Q$count\E<}s);
}

