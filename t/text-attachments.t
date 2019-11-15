#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 26;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0textattach0';
my $site = create_site($schema, $site_id);

my %titles;

foreach my $i (1..2) {
    my ($rev) = $site->create_new_text({ title => "$i Hello $i",
                                         textbody => '',
                                       }, 'text');
    my @body;
    foreach my $f (qw/shot.jpg shot.pdf shot.png big.jpeg/) {
        my $got = $rev->add_attachment(catfile(t => files => $f))->{attachment};
        ok $got and diag $got;
        $rev->edit($rev->muse_body . "\n\n[[$got]]\n\n");
        push @body, $got;
    }
    my @header;
    foreach my $f (qw/shot.jpg shot.pdf shot.png big.jpeg/) {
        my $got = $rev->add_attachment(catfile(t => files => $f))->{attachment};
        ok $got;
        push @header, $got;
    }
    $rev->edit("#ATTACH " . join(' ', @header) . "\n" . $rev->muse_body);
    my $cover;
    {
        $cover = $rev->add_attachment(catfile(t => files => 'shot.jpg'))->{attachment};
        ok $cover;
        $rev->edit("#cover $cover\n" . $rev->muse_body);
    }
    diag $rev->muse_body;
    $rev->commit_version;
    $rev->publish_text(sub { diag @_ });
    my $title = $rev->title;
    $titles{$title->uri} = {
                            body => [ sort @body ],
                            cover => [$cover],
                            header => [ sort @header ],
                           };
}

foreach my $uri (keys %titles) {
    my $data = $titles{$uri};
    my @attachments = map { @{$data->{$_}} } keys %$data;
    print Dumper \@attachments;
}

foreach my $title ($site->titles->by_uri([ keys %titles ])->all) {
    diag $title->uri;
    # diag $title->muse_body;
    my @images = sort map { $_->uri } $title->images;
    my $spec = $titles{$title->uri};
    is scalar(@images), 3;

    is_deeply \@images, [ grep { /\.(png|jpg)$/ } @{$spec->{body}} ], "->images seems to work";

    my @all_images =  grep { /\.(png|jpg)$/ } (@{$spec->{body}}, @{$spec->{cover}}, @{$spec->{header}});

    is($title->attachments->images_only->count, scalar(@all_images)) or diag Dumper(\@all_images);

    my @all_atts = (@{$spec->{body}}, @{$spec->{cover}}, @{$spec->{header}});

    # File which was uploaded but not referenced ignored, we can't get it from parsing the body,
    # hence, -1.

    is($title->attachments->count, @all_atts - 1, "Attachment count is fine") or diag Dumper(\@all_atts);
}

