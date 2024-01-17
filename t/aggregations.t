#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 80;
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
           aggregation_uri => "antology",
           aggregation_name => "My Antology",
           titles => [
                      'to-test-one',
                     ],
           publication_date => "Never",
           publisher => "Nobody",
           publication_place => 'Another',
           sorting_pos => 0,
           publication_date_year => 2023,
           publication_date_month => 12,
           publication_date_day => 1,
          },
          {
           aggregation_series => {
                                  aggregation_series_uri => 'fmx',
                                  aggregation_series_name => 'For Marco',
                                  publisher => 'Publisher',
                                  publication_place => 'Place',
                                 },
           aggregation_uri => "fmx-1",
           isbn => '97899999999999',
           issue => "#1",
           sorting_pos => 1,
           titles => [
                      'to-test-one',
                      'to-test-two',
                      'to-test-three',
                     ],
           publication_place => "Nowhere",
          },
          {
           aggregation_series => {
                                  aggregation_series_uri => 'fmx',
                                  aggregation_series_name => 'For Marco',
                                  publisher => 'Publisher',
                                  publication_place => 'Place',
                                 },
           aggregation_uri => "fmx-2",
           issue => "#2",
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
push @{$ag->[1]->{titles}}, 'non-existent', 'to-test-one';
push @{$ag->[2]->{titles}}, 'non-existent-1';

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

is $site->aggregations->count, 3;
is $site->aggregations->search_related('aggregation_titles')->count, 9;

# the last one is a duplicate
is pop @{$ag->[1]->{titles}}, "to-test-one";
{
    my $serialized = $site->serialize_aggregations;
    is_deeply $serialized, $ag or die Dumper($serialized, $ag);
}
diag "Reimporting";

my $removed = pop @{$copy->[2]->{titles}};

DumpFile($autoimport->child('aggregations.yml'), $copy);
$site->process_autoimport_files;
is $site->aggregations->search_related('aggregation_titles')->count, 6;

is_deeply $site->serialize_aggregations, $copy;

is $site->aggregations->no_match->count, 0;

foreach my $title ($site->titles->search({ uri => $removed })) {
    is $title->aggregations->count, 2 or die Dumper($copy);
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
\s+<subfield\s+code="d">Nowhere\sPublisher</subfield>
\s+<subfield\s+code="q">1</subfield>
\s+</datafield>
}sx) or die $mech->content;

$mech->get_ok('/aggregation/fmx-1?bare=1') or die;
$mech->content_like(qr{Title one.*Title two.*Title three}s) or die $mech->content;
$mech->get_ok('/aggregation/fmx-2');
$mech->content_like(qr{Title three.*Title two}s);

foreach my $title ($site->titles) {
    $mech->get_ok($title->full_uri);
    $mech->content_contains('/aggregation/fmx');
}

foreach my $agg ($site->aggregations) {
    my @titles = $agg->titles;
    ok scalar(@titles);
}
my @ids = map { $_->aggregation_id } $site->aggregations;

foreach my $title ($site->titles) {
    my $pmh_date = $title->oai_pmh_records->first->zulu_datestamp;
    sleep 1;
    foreach my $id (@ids) {
        $title->aggregate({ add_aggregation_id => $id });
    }
    ok $title->aggregate({ remove_aggregation => $ids[0] });
    ok $title->aggregate({ remove_aggregation => \@ids });
    $title->discard_changes;
    is $title->aggregations->count, 0, "Aggregations removed";
    foreach my $id (@ids) {
        ok $title->aggregate({
                              remove_aggregation => $id,
                              add_aggregation_id => $id,
                             });
    }
    $title->discard_changes;
    is scalar(@ids), $title->aggregations->count, "Aggregations restored";
    my $new_date = $title->oai_pmh_records->first->zulu_datestamp;
    ok $new_date gt $pmh_date, "$new_date > $pmh_date";
}
# reset
$site->process_autoimport_files;

{
    $mech->get('/aggregate/edit/' . $ids[0]);
    is $mech->status, 401, "Bounced to login";
    ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
       "Found login form");
    is $mech->uri->path, '/aggregate/manage';
    $mech->get_ok('/aggregate/edit/' . $ids[0]);
    is $mech->uri->path, '/aggregate/manage';
    $mech->content_contains('autoimport file present');
    my $text_uri = $site->titles->first->full_uri;
    $mech->get_ok($text_uri);
    $mech->content_lacks('id="annotation-editor-aggregations"');

    $autoimport->child('aggregations.yml')->remove;

    $mech->get('/aggregate/edit/' . $ids[0]);
    is $mech->uri->path, '/aggregate/edit/' . $ids[0];
    $mech->get_ok($text_uri);
    $mech->content_contains('id="annotation-editor-aggregations"');
}



my $dump = $site->serialize_site;
$site->delete;
{
    my @save = @{$dump->{aggregations}};
    my $newsite = $schema->resultset('Site')->deserialize_site($dump);
    is scalar(@save), 3;
    is_deeply $save[1]{titles}, [ 'to-test-one', 'to-test-two', 'to-test-three'];
    is $save[2]{publication_date}, "Never";
    is_deeply $newsite->serialize_aggregations, \@save;
    diag Dumper(\@save);
}
