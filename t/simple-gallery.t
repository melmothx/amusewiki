#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 312;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{AMW_NO_404_FALLBACK} = 1;
};

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
$site->update({ secure_site => 0 });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

{
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         textbody => '<p>ciao</p>',
                                         uri => 'h-o-hello-1',
                                       }, 'text');

}

{
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         textbody => '<p>ciao</p>',
                                       }, 'text');
    my $pdf = catfile(qw/t files shot.pdf/);
    my $got = $rev->add_attachment($pdf);
    diag Dumper($got);
    ok $got->{attachment};
    $rev->edit("#ATTACH $got->{attachment}\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    $mech->content_contains('id="amw-attached-pdfs"');
    $mech->content_contains("/$got->{attachment}");
    $mech->content_lacks("col-xs-4 pdf-gallery");
    $mech->get_ok('/uploads/' . $site->id . '/' . $got->{attachment});
    $mech->get_ok('/uploads/' . $site->id . '/thumbnails/' . $got->{attachment} . '.thumb.png');
    $mech->get('/' . $got->{attachment});
    diag "Testing if the fallback is hit (it shouldn't)";
    is $mech->status, '404';
}

foreach my $type (qw/text special/) {
    my ($rev) = $site->create_new_text({ title => 'HELLO-2',
                                         textbody => '<p>ciao</p>',
                                       }, $type);
    my $pdf = catfile(qw/t files shot.pdf/);
    my $png = catfile(qw/t files shot.png/);
    my @pdfs;
    for my $i (1..4) {
        my $got = $rev->add_attachment($pdf);
        push @pdfs, $got->{attachment};
        my $a_png = $rev->add_attachment($png);
        push @pdfs, $a_png->{attachment};
        if ($i == 1) {
            $rev->edit("#cover $a_png->{attachment}\n" . $rev->muse_body);
        }
    }
    diag Dumper(\@pdfs);
    ok(scalar(@pdfs));
    $rev->edit("#ATTACH " . join(' ', @pdfs) . "\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    foreach my $m (qw/cover_uri cover_thumbnail_uri cover_small_uri cover_large_uri/) {
        ok $title->$m;
        $mech->get_ok($title->$m);
    }
    $mech->get_ok($title->full_uri);
    $mech->content_contains('id="amw-attached-pdfs"');
    $mech->content_contains('col-sm-4 pdf-gallery');
    foreach my $att (@pdfs) {
        $mech->get($title->full_uri);
        $mech->content_contains('/uploads/' . $site->id . '/thumbnails/' . $att . '.thumb.png');
        my $att_object = $site->attachments->by_uri($att);
        foreach my $method (qw/full_uri thumbnail_uri small_uri large_uri/) {
            ok ($att_object->$method, "$method ok: " . $att_object->$method);
            $mech->get_ok($att_object->$method);
        }
    }
}

foreach my $att ($site->attachments) {
    foreach my $method (qw/full_uri thumbnail_uri small_uri large_uri/) {
        ok ($att->$method, "$method ok: " . $att->$method);
        $mech->get_ok($att->$method);
    }
}

