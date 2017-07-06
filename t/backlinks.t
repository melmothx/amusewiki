#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 48;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0backlinks0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0,
                pdf => 0,
                epub => 0,
                html => 1,
              });

my $stub = <<'MUSE';
#title TITLE
#lang en

This one references [[LINK0]] [[/library/LINK1]] [[/special/LINK2]] [[./LINK3]]

This one references [[../special/LINK4][one]] [[../library/LINK5][two]] [[./LINK6][three]]

This one references [[LINK0]] [[/library/LINK1]] [[/special/LINK2]] [[./LINK3]]

This one references [[LINK4#toc11][one]] [[/library/LINK5/edit][two]] [[./LINK6?param=1][three]]

And link to itself [[TITLE]] [[./TITLE][myself]]

MUSE

# we need to create 8 texts + 8 specials with the same name

my @titles;
foreach my $type (qw/text special/) {
    foreach my $id (1..8) {
        my ($rev, $err) = $site->create_new_text({
                                                  title => "title-$id",
                                                  lang => 'en',
                                                 }, $type);

        die $err if $err;
        my $body = $stub;
        my @links = map { 'title-' . $_ } grep { $id ne $_ } (1..8);
        $body =~ s/TITLE/title-$id/g;
        $body =~ s/LINK([0-6])/$links[$1]/g;
        $rev->edit($body);
        $rev->commit_version;
        $rev->publish_text;
        ok $rev->title->full_uri;
        push @titles, $rev->title;
    }
}

foreach my $title ($site->titles) {
    is $title->text_internal_links->count, 14, "14 links found in the text";
    ok $title->backlinks->count, "Count of backlinks for " . $title->full_uri .  " is fine: "
      . $title->backlinks->count;
    foreach my $backlink ($title->backlinks->all) {
        diag $backlink->full_uri;
    }
}

