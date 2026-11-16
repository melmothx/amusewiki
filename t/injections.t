#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
};

use Test::More tests => 2;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Path::Tiny;
use Data::Dumper::Concise;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0injection0');

my $muse = path($site->repo_root, qw/t tt test.muse/);
$muse->parent->mkpath;

$muse->spew_utf8(<<"MUSE");
#title Test
#subtitle Another Test
#id asdf
#site_id bla
#f_suffix Text
#status rand

Test

MUSE

$site->update_db_from_tree(sub { diag join(' ', @_) });

diag $site->titles->first->id;
my $title = $site->titles->first;
foreach my $h ($title->muse_headers) {
    diag Dumper({$h->get_columns});
}

isnt $title->id, "asdf";
isnt $title->status, "rand";

