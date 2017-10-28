#!perl
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More;
use File::Spec::Functions;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $site_map = $mech->get_ok('/sitemap.txt');
my @urls = grep { $_ } split /\n/, $mech->content;

my $opengraph = path(repo => '0blog0', site_files => 'opengraph.png');
my $navlogo = path(repo => '0blog0', site_files => 'navlogo.png');
my $pagelogo = path(repo => '0blog0', site_files => 'pagelogo.png');

die unless $navlogo->exists;

foreach my $f ($opengraph, $pagelogo) {
    $navlogo->copy($f);
}
ok $site->index_site_files;

$opengraph->remove if $opengraph->exists;
$pagelogo->remove  if $pagelogo->exists;

push @urls, qw[ /search /help/opds /help/irc /latest/2 ];

ok $site->index_site_files;

check_urls($navlogo->basename, @urls);

$navlogo->copy($opengraph);

ok $site->index_site_files;

check_urls($opengraph->basename, @urls);

$opengraph->remove;

$navlogo->copy($pagelogo);

ok $site->index_site_files;

check_urls($pagelogo->basename, @urls);

$pagelogo->remove;

ok $site->index_site_files;

sub check_urls {
    my ($image, @pages) = @_;
  foreach my $url (@pages) {
    next if $url =~ m{blog.amusewiki.org/(feed|opds)};
    diag "Checking $url";
    $mech->get_ok($url);
    my $content = $mech->content;
    my %og;
    while ($content =~ m{<meta property="(.*)" content="(.*?)" />}g) {
        my $p = $1;
        my $c = $2;
        if (exists $og{$p}) {
            if (ref($og{$p})) {
                push @{$og{$p}}, $c;
            }
            else {
                $og{$p} = [$og{$p}];
                push @{$og{$p}}, $c;
            }
        }
        else {
            $og{$p} = $c;
        }
    }
    diag Dumper(\%og);
    foreach my $c (qw/title type image url description/) {
        ok $og{"og:$c"}, "Found mandatory og:$c " . $og{"og:$c"};
    }
    like $og{'og:image'}, qr{\Q$image\E$}, "Image is $image";
    $mech->get_ok($og{'og:image'});
    $mech->get_ok($og{'og:url'});
  }
}
done_testing;
