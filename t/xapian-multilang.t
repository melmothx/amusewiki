#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 29;
use Data::Dumper;
use Path::Tiny;

my $site_id = '0searchmulti0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

foreach my $term ('training', 'blabla') {
    my $file = path($site->repo_root, qw/t tt/, 'test-term-' . $term . '.muse');
    $file->parent->mkpath;
    $file->spew_utf8("#title $term\n#lang en\n\n$term\n");
}
{
    my $file = path($site->repo_root, qw/t tt/, 'test-term-italian.muse');
    $file->parent->mkpath;
    $file->spew_utf8("#title Alberi\n#lang it\n\nLa foresta piena di alberi\n");
}
$site->update_db_from_tree(sub { diag @_ });
is $site->titles->count, 3, "3 titles";

foreach my $lang (qw/en de/) {
    ok !$site->multilanguage, "Site is not multilanguage";
    ok $site->xapian->stem_search, "Xapian will try to stem";
    my ($total, @results) = $site->xapian->search(qq{training}, 1, $lang);
    is(scalar(@results), 1, "Found 1 result for training with lang $lang");
    if ($lang eq $site->locale) {
        ($total, @results) = $site->xapian->search(qq{train}, 1, $lang);
        is(scalar(@results), 1, "Found 1 result for train with lang $lang");
    }
    else {
        ($total, @results) = $site->xapian->search(qq{train}, 1, $lang);
        is(scalar(@results), 0, "Found 0 result for train with lang $lang");
    }
    ($total, @results) = $site->xapian->search(qq{train*}, 1, $lang);
    is(scalar(@results), 1, "Found 1 result for train* with lang $lang");
}

{
    my ($total, @results) = $site->xapian->search(qq{albero}, 1, 'it');
    ok (!@results, "Stemmer not activated");

    # this is the real problem:
    ($total, @results) = $site->xapian->search(qq{alberi}, 1, 'en');
    # as you can see, searching in english for a verbatim string in
    # italian, which is actually present in the document, return 0
    # results because of the stemming.
    ok (!@results, "Searching verbatim with en is not fine, because of the stemmer");

    $site->update({ locale => 'it' });
    ($total, @results) = $site->xapian->search(qq{albero}, 1, 'it');
    is (scalar(@results), 1, "Stemmer activated when locale was changed");

    ($total, @results) = $site->xapian->search(qq{alberi}, 1, 'it');
    is (scalar(@results), 1, "Stemmer activated when locale was changed");


    # now searching verbatim in english is fine
    ($total, @results) = $site->xapian->search(qq{alberi}, 1, 'en');
    is (scalar(@results), 1, "Verbatim english search is fine");

    $site->update({ multilanguage => 'it en' });
    ($total, @results) = $site->xapian->search(qq{albero}, 1, 'it');
    is (scalar(@results), 0, "Stemmer not activated for multinguage site");

    foreach my $lang (qw/en it de/) {
        foreach my $term ('alberi', 'alber*', 'train*', 'training') {
            my ($total, @results) = $site->xapian->search($term, 1, $lang);
            is (scalar(@results), 1, "Verbatim search works for $term and $lang");
        }
    }
}
