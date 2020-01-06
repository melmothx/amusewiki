#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Test::More tests => 46;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0parent0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $suffix (qw/a b/) {
    my $parent_uri = "parent-t-$suffix";
    my $file = path($site->repo_root, qw/p pt/, "$parent_uri.muse");
    $file->parent->mkpath;
    my $muse = <<"MUSE";
#author Author
#title My parent text X $suffix X
#topics Topic $suffix
#authors Author
#lang en

This is the introduction for $suffix

MUSE
    $file->spew_utf8($muse);
    undef $file;
    foreach my $i (1..3) {
        my $file = path($site->repo_root, qw/c cc/, "c-child-$suffix-$i.muse");
        $file->parent->mkpath;
        my $muse = <<"MUSE";
#author Author $suffix $i
#title My child text X $suffix $i X
#parent $parent_uri
#lang en
#topics Topic dummy
#authors Author dummy

This is the XX $i XX body for $suffix

MUSE
        $file->spew_utf8($muse);
    }
}


$site->update_db_from_tree(sub { diag @_ });

foreach my $text ($site->titles->search({ uri => { -like => 'c-child-%' } })) {
    ok $text->parent;
    diag $text->parent;
    ok $text->parent_text;
    is $text->children_texts->count, 0;
    is $text->parent_text->children_texts->count, 3;
    is $text->categories->count, 0, "No categories set in the child text";
    my $expected = $text->parent_text->display_categories;
    diag Dumper($expected);
    is_deeply $text->display_categories, $expected;
}
foreach my $text ($site->titles->search({ uri => { -like => 'parent-t-%' } })) {
    ok $text->categories->count, "Found categories set in the parent text";
    ok !$text->parent_text;
    is $text->children_texts->count, 3;
}

{
    my $file = path($site->repo_root, qw/s sf/, "self.muse");
    $file->parent->mkpath;
    my $muse = <<"MUSE";
#author Author
#title Self-referencing
#topics Topic self
#authors Author
#lang en
#parent self

This is a recursive one

MUSE
    $file->spew_utf8($muse);
    $site->update_db_from_tree(sub { diag @_ });
}

foreach my $text ($site->titles->search({ uri => 'self' })) {
    ok $text->parent;
    ok $text->parent_text;
    is $text->children_texts->count, 1;
    diag Dumper($text->display_categories);
    is_deeply $text->display_categories, [];
}
