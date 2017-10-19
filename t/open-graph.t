#!perl
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More tests => 181;
use File::Spec::Functions;
use Cwd;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $site_map = $mech->get_ok('/sitemap.txt');
my @urls = grep { $_ } split /\n/, $mech->content;
push @urls, qw[ /search /help/opds /help/irc /latest/2 ];
foreach my $url (@urls) {
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
    foreach my $c (qw/title type image url/) {
        ok $og{"og:$c"}, "Found mandatory og:$c " . $og{"og:$c"};
    }
    $mech->get_ok($og{'og:url'});
}
