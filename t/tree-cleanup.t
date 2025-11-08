#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More tests => 100;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cleanup0';
my $site = create_site($schema, $site_id);
$site->update({pdf => 1});
$site->check_and_update_custom_formats;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $title (qw/one two three/) {
    my $muse = path($site->repo_root, qw/t tt/, "to-test-$title.muse");
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#authors Author $title; Authors $title; Pinco, Pallino
#title Title $title
#topics Topic $title
#lang en
#author My author $title

Test $title
MUSE
}
path($site->repo_root, specials => 'index.muse')->spew_utf8(<<"MUSE");
#title Test

Test
MUSE

$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

$mech->get_ok('/mirror.txt');
$mech->content_contains('mirror/t/tt/to-test-one.epub');

path($site->repo_root, qw/t tt to-test-one.muse/)->remove;
{
    my $file = path($site->repo_root, qw/t tt to-test-two.muse/);
    my $body = $file->slurp_utf8;
    $file->spew_utf8("#DELETED removed\n$body");
}
path($site->repo_root, specials => 'index.muse')->remove;
foreach my $ext (qw/tex pdf html bare.html epub zip/) {
    {
        my $file = path($site->repo_root, specials => "index.$ext");
        $mech->get_ok("/mirror/specials/index.$ext");
        ok $file->exists, "$file exists";
    }
    foreach my $f (qw/one two three/) {
        my $file = path($site->repo_root, qw/t tt/, "to-test-$f.$ext");
        ok $file->exists, "$file exists";
        $mech->get_ok("/mirror/t/tt/to-test-$f.$ext");
    }
}


$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}
foreach my $ext (qw/tex pdf html bare.html epub zip/) {
    {
        my $file = path($site->repo_root, specials => "index.$ext");
        ok !$file->exists, "$file is gone";
        $mech->get("/mirror/specials/index.$ext");
        is $mech->status, 404;
    }
    foreach my $f (qw/three/) {
        my $file = path($site->repo_root, qw/t tt/, "to-test-$f.$ext");
        ok $file->exists, "$file exists";
        $mech->get_ok("/mirror/t/tt/to-test-$f.$ext");
    }
    foreach my $f (qw/two one/) {
        my $file = path($site->repo_root, qw/t tt/, "to-test-$f.$ext");
        $mech->get("/mirror/t/tt/to-test-$f.$ext");
        is $mech->status, 404;
        ok !$file->exists, "$file is gone";
    }
}
$mech->get_ok('/mirror.txt');
$mech->content_lacks('mirror/t/tt/to-test-one.epub');
