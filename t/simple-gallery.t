#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 33;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
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
}

foreach my $type (qw/text special/) {
    my ($rev) = $site->create_new_text({ title => 'HELLO-2',
                                         textbody => '<p>ciao</p>',
                                       }, $type);
    my $pdf = catfile(qw/t files shot.pdf/);
    my @pdfs;
    for (1..4) {
        my $got = $rev->add_attachment($pdf);
        push @pdfs, $got->{attachment};
    }
    diag Dumper(\@pdfs);
    ok(scalar(@pdfs));
    $rev->edit("#ATTACH " . join(' ', @pdfs) . "\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    $mech->content_contains('id="amw-attached-pdfs"');
    $mech->content_contains('col-sm-4 pdf-gallery');
    $mech->content_contains('/uploads/' . $site->id . '/thumbnails/' . $pdfs[0] . '.thumb.png');
    foreach my $att (@pdfs) {
        $mech->get_ok('/uploads/' . $site->id . '/' . $att);
        $mech->get_ok('/uploads/' . $site->id . '/thumbnails/' . $att . '.thumb.png');
    }
    
}
