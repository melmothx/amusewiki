#!perl
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0ogp0');

my $imagefile = path(qw/t files shot.png/);
$imagefile->copy(path($site->path_for_site_files, 'navlogo.png'));

{
    my ($rev) = $site->create_new_text({ title => 'hello there',
                                         lang => 'hr',
                                         textbody => '<p>ciao</p>',
                                       }, 'text');
    my $att = $rev->add_attachment("$imagefile")->{attachment};
    $rev->edit("#cover $att\n#author pinco pallino, caio, sempronio\n#teaser Here!\n#SORTtopics blabla, blaba\n"
               . $rev->muse_body);
    ok $att;
    $rev->commit_version;
    $rev->publish_text;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $site_map = $mech->get_ok('/sitemap.txt');
my @urls = grep { $_ } split /\n/, $mech->content;

my $opengraph = path($site->path_for_site_files, 'opengraph.png');
my $navlogo = path($site->path_for_site_files,'navlogo.png');
my $pagelogo = path($site->path_for_site_files,'pagelogo.png');

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

my $og = check_url('/library/hello-there', 'h-t-hello-there-1.png.large.png');

is_deeply $og,
  {
   "og:article:author" => "pinco pallino, caio, sempronio",
   "og:article:tag" => [
                        "blaba",
                        "blabla"
                       ],
   "og:description" => "Here!",
   "og:image" => "https://0ogp0.amusewiki.org/uploads/0ogp0/thumbnails/h-t-hello-there-1.png.large.png",
   "og:image:height" => 381,
   "og:image:width" => 300,
   "og:title" => "hello there",
   "og:type" => "article",
   "og:url" => "https://0ogp0.amusewiki.org/library/hello-there"
  }, "hello-there looks good";


sub check_urls {
    my ($image, @pages) = @_;
    foreach my $url (@pages) {
        next if $url =~ m{amusewiki\.org/(feed|opds)};
        next if $url =~ m{amusewiki\.org/library/hello-there};
        check_url($url, $image);
    }
}
sub check_url {
    my ($url, $image) = @_;
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
    foreach my $c (qw/title type image url description image:width image:height/) {
        ok $og{"og:$c"}, "Found mandatory og:$c " . $og{"og:$c"};
    }
    like $og{'og:image'}, qr{\Q$image\E$}, "Image is $image";
    $mech->get_ok($og{'og:image'});
    $mech->get_ok($og{'og:url'});
    return \%og;
}



done_testing;
