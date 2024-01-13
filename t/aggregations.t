#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 2;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use URI;
use YAML qw/DumpFile/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0aggregation0';
my $site = create_site($schema, $site_id);
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


my $autoimport = path($site->autoimport_dir);
$autoimport->mkpath;
DumpFile($autoimport->child('aggregations.yml'),
         [
          {
           aggregation_code => "fmx",
           aggregation_uri => "fmx-1",
           aggregation_name => "For Marco",
           series_number => "#1",
           sorting_pos => 1,
           titles => [
                      'to-test-one',
                      'to-test-two',
                      'non-existent',
                      'to-test-three',
                     ],
           publication_place => "Nowhere",
          },
          {
           aggregation_code => "fmx",
           aggregation_uri => "fmx-2",
           aggregation_name => "For Marco",
           series_number => "#2",
           sorting_pos => 1,
           titles => [
                      'to-test-three',
                      'to-test-two',
                      'to-test-one',
                      'non-existent-1',
                     ],
           publication_date => "Never",
           publisher => "Nobody",
          },
         ]);

foreach my $title (qw/one two tree/) {
    my $muse = path($site->repo_root, qw/t tt/, "to-test-$title.muse");
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#authors Author $title; Authors $title; Pinco, Pallino
#title Title $title
#lang en
#author My author

Test $title
MUSE
}

$site->git->add("$autoimport");
$site->git->add('t');
$site->git->commit({ message => "Added files" });
diag "Updating DB from tree";
$site->update_db_from_tree;

is $site->aggregations->count, 2;
is $site->aggregations->search_related('aggregation_titles')->count, 8;
