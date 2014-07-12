#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 115;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use Data::Dumper;
use File::Slurp qw/write_file/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0multi0';
my $site = create_site($schema, $site_id);
$site->multilanguage(1);
$site->update->discard_changes;

my $root = $site->repo_root;
my $filedir = catdir($root, qw/a at/);
my $specialdir = catdir($root, 'specials');
make_path($filedir);
make_path($specialdir);

die "$filedir doesn't exist" unless -d $filedir;

my @langs = (qw/en hr it/);
my @uids  = (qw/id1 id2 id3/);

my @texts;
foreach my $lang (@langs) {
    # generate the indexes
    my $index = "index-$lang";
    my $indexfilename = catfile($specialdir, $index . '.muse');
    my $body =<<"MUSE";
#title Index ($lang)
#lang $lang

This is the $lang index

MUSE
    write_file($indexfilename, { binmode => ':encoding(utf-8)' }, $body);

    foreach my $uid (qw/id1 id2 id3/) {
        # create the muse files
        my $basename = "a-test-$uid-$lang";
        push @texts, $basename;
        my $filename = catfile($filedir, $basename . '.muse');
        my $body =<<"MUSE";
#title $lang-$uid
#uid $uid
#lang $lang
#topics Test
#author Marco

Blabla *bla* has uid $uid and lang $lang

MUSE
        write_file($filename, { binmode => ':encoding(utf-8)' }, $body);
    }
}

$site->update_db_from_tree;


use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok('/library');

$mech->get_ok('/archive');

foreach my $text (@texts) {
    $mech->content_contains($text);
}

foreach my $path ("/archive", "/topics/test") {
    foreach my $lang (@langs) {
        $mech->get_ok("$path/$lang");
        foreach my $uid (@uids) {
            $mech->content_contains("/library/a-test-$uid-$lang");
        }
        my @others = grep { $_ ne $lang } @langs;
        foreach my $other (@others) {
            foreach my $uid (@uids) {
                $mech->content_lacks("/library/a-test-$uid-$other");
            }
        }
    }
}

foreach my $ttext (@texts) {
    my $text = $ttext;
    $mech->get_ok("/library/$text");
    $mech->content_contains("translations");
    my $others = $text;
    if ($text =~ m/^(.+-)([a-z]+)$/) {
        my $base = $1;
        my $current = $2;
        foreach my $lang (@langs) {
            next if $lang eq $current;
            $mech->content_contains("/library/$base$lang");
        }
    }
}


$mech->get("/archive/ru");
is $mech->status, "404", "No russian texts, no archive/ru";
$mech->get("/topics/test/ru");
is $mech->status, "404", "No russian texts, no topics/test/ru";

my $text = $site->titles->find({ uri => "a-test-id2-hr" });
my @translations = $text->translations;
is (scalar(@translations), 2, "Found two translations");
foreach my $tr (@translations) {
    ok ($tr->full_uri, "Found " . $tr->full_uri);
}

my $without = $schema->resultset('Title')->find({ uri => 'second-test',
                                                  f_class => 'text',
                                                  site_id => '0blog0' });

ok($without, "Found the text");

@translations = $without->translations;
ok(!@translations, "No translations found");

my @sites = $site->other_sites;
ok(!@sites, "No related sites found");
