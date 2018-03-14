#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 7;
use Data::Dumper::Concise;
use Path::Tiny;
use JSON::MaybeXS;

my $site_id = '0facets1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

my $xapian = $site->xapian;
ok $xapian;
diag $xapian->specification_file;

# force removal
eval { $xapian->specification_file->remove };
ok !$xapian->database_is_up_to_date;

$xapian->write_specification_file;
my $spec = $xapian->read_specification_file;
diag "Current version is $spec->{version}";
ok $spec->{version};
diag "Current version is $spec->{version}";
ok $xapian->database_is_up_to_date;

{
    my $file = path($site->repo_root, qw/t t1 test1.muse/);
    $file->parent->mkpath;
    my $muse = <<'MUSE';
#title First test
#topics kuća, snijeg, škola, peć
#authors pinkić palinić, kajo šempronijo
#pubdate 2013-12-25
#date -1993-
#lang en

** This is a book common

** Because it has sectioning

MUSE
    $file->spew_utf8($muse);
}

$site->update_db_from_tree(sub { diag @_ });

my $before = $site->xapian->faceted_search(fmt => 'json', site => $site)->json_output;

diag Dumper($before);

eval { $xapian->specification_file->remove };
ok !$xapian->database_is_up_to_date;
$site->xapian_reindex_all;
ok $xapian->database_is_up_to_date;

my $after = $site->xapian->faceted_search(fmt => 'json', site => $site)->json_output;

is_deeply($after, $before) or diag Dumper([$after, $before]);
