#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 39;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use URI;
use YAML qw/DumpFile LoadFile/;

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
my $ag = [
          {
           aggregation_code => "fmx",
           aggregation_uri => "fmx-1",
           aggregation_name => "For Marco",
           isbn => '97899999999999',
           series_number => "#1",
           sorting_pos => 1,
           titles => [
                      'to-test-one',
                      'to-test-two',
                      'to-test-three',
                     ],
           publication_place => "Nowhere",
          },
          {
           aggregation_code => "fmx",
           aggregation_uri => "fmx-2",
           aggregation_name => "For Marco",
           series_number => "#2",
           sorting_pos => 2,
           titles => [
                      'to-test-three',
                      'to-test-two',
                      'to-test-one',
                     ],
           publication_date => "Never",
           publisher => "Nobody",
          },
         ];
DumpFile($autoimport->child('aggregations.yml'), $ag);
my $copy = LoadFile($autoimport->child('aggregations.yml'));

# and a duplicate
push @{$ag->[0]->{titles}}, 'non-existent', 'to-test-one';
push @{$ag->[1]->{titles}}, 'non-existent-1';

DumpFile($autoimport->child('aggregations.yml'), $ag);

foreach my $title (qw/one two three/) {
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

is_deeply $site->serialize_aggregations, $copy;

sleep 1;

diag "Reimporting";

my $removed = pop @{$copy->[1]->{titles}};

DumpFile($autoimport->child('aggregations.yml'), $copy);
$site->process_autoimport_files;
is $site->aggregations->search_related('aggregation_titles')->count, 5;

is_deeply $site->serialize_aggregations, $copy;

is $site->aggregations->no_match->count, 0;

foreach my $title ($site->titles) {
    if ($title->uri eq $removed) {
        is $title->aggregations->count, 1;
    }
    else {
        is $title->aggregations->count, 2;
    }
    diag "The aggregations sorted are " . Dumper([$title->aggregations->sorted->hri->all]);
}

while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}


foreach my $rec ($site->oai_pmh_records) {
    ok $rec->marc21_record;
}

$mech->get_ok('/oai-pmh?verb=ListRecords&metadataPrefix=marc21');
$mech->content_like(qr{
\s+<datafield\s+tag="773"\s+ind1="\s+"\s+ind2="\s+">
\s+<subfield\s+code="t">For\s+Marco</subfield>
\s+<subfield\s+code="g">\#1</subfield>
\s+<subfield\s+code="o">fmx-1</subfield>
\s+<subfield\s+code="6">https://0aggregation0.amusewiki.org/aggregation/fmx-1</subfield>
\s+<subfield\s+code="z">97899999999999</subfield>
\s+<subfield\s+code="d">Nowhere</subfield>
\s+</datafield>
}sx);

$mech->get_ok('/aggregation/fmx-1');
$mech->content_like(qr{Title one.*Title two.*Title three}s);
$mech->get_ok('/aggregation/fmx-2');
$mech->content_like(qr{Title three.*Title two}s);

foreach my $title ($site->titles) {
    $mech->get_ok($title->full_uri);
    $mech->content_contains('/aggregation/fmx');
}
