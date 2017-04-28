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
use Test::More tests => 6;
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
$site->update_db_from_tree(sub { diag @_ });
is $site->titles->count, 2, "2 titles";

foreach my $lang (qw/en de/) {
    my ($total, @results) = $site->xapian->search(qq{training}, 1, $lang);
    is(scalar(@results), 1, "Found 1 result for training with lang $lang");
    if ($lang eq 'en') {
        ($total, @results) = $site->xapian->search(qq{train}, 1, $lang);
        is(scalar(@results), 1, "Found 1 result for train with lang $lang");
    }
    ($total, @results) = $site->xapian->search(qq{train*}, 1, $lang);
    is(scalar(@results), 1, "Found 1 result for train* with lang $lang");
}

