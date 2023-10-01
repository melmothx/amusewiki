#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 8;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0annotate0';
my $site = create_site($schema, $site_id);
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $title (qw/one two tree/) {
    my $muse = path($site->repo_root, qw/t tt/, "to-test-$title.muse");
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#authors Author $title; Authors $title 
#title Title $title
#topics First $title; Second #title
#lang en

Test $title
MUSE
}

$site->git->add('t');
$site->git->commit({ message => "Added files" });
diag "Updating DB from tree";
$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

my $annotation = $site->annotations->create({
                                             annotation_name => "Original",
                                             annotation_type => "file",
                                            });

foreach my $title ($site->titles->all) {
    $title->add_to_title_annotations({
                                      annotation => $annotation,
                                      annotation_value => "/my/file.doc for " . $title->title,
                                     });
    ok $title->title_annotations->count;
    is $title->title_annotations->first->title->id, $title->id;
}
ok $site->annotations->count;
ok $annotation->title_annotations->count;
