#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 131;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use URI;
use YAML qw/DumpFile LoadFile Dump Load/;

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
#topics Topic $title
#lang en
#author My author $title

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

{
    my $agg = $site->aggregations->by_uri('fmx-1')->single;
    ok $agg;
    my $ctypes = $agg->display_categories;
    ok @$ctypes;
    my @expect = (
                  '/category/author/author-one',
                  '/category/author/authors-one',
                  '/category/author/authors-three',
                  '/category/author/authors-two',
                  '/category/author/author-three',
                  '/category/author/author-two',
                  '/category/author/pinco-pallino',
                  '/category/topic/topic-one',
                  '/category/topic/topic-three',
                  '/category/topic/topic-two',
                 );
    my @got;
    foreach my $ctype (@{$ctypes}) {
        foreach my $cat (@{$ctype->{entries}}) {
            push @got, $cat->full_uri;
        }
    }
    is_deeply(\@got, \@expect);
}

{
    my $node = $site->nodes
      ->update_or_create_from_params({
                                      uri => 'pallino',
                                      canonical_title => "Pallino",
                                      attached_uris => '/aggregation/fmx-2 /series/fmx',
                                     });
    is($node->serialize->{attached_uris}, "/series/fmx\n/aggregation/fmx-2");
}


my $dump = $site->serialize_site;
$site->delete;
{
    my $deep_copy = Load(Dump($dump));
    my @save = @{$dump->{aggregations}};
    my $newsite = $schema->resultset('Site')->deserialize_site($dump);
    is scalar(@save), 3;
    is_deeply $save[1]{titles}, [ 'to-test-one', 'to-test-two', 'to-test-three'];
    is $save[2]{publication_date}, "Never";
    is_deeply $newsite->serialize_aggregations, \@save;
    diag Dumper(\@save);
    my $fresh_dump = $newsite->serialize_site;
    diag Dumper($fresh_dump);
    is $fresh_dump->{nodes}->[0]->{attached_uris}, "/series/fmx\n/aggregation/fmx-2";
    is_deeply $fresh_dump, $deep_copy or die Dumper({ new => $fresh_dump, old => $deep_copy });
    is $newsite->aggregation_series->count, 1;
    is $newsite->aggregations->count, 3;
    $newsite->bootstrap_archive({ full => 1, logger => sub { diag @_ } });
    $site = $newsite;
}

{
    # session are lost after the reloading
    $mech->get('/aggregate/manage');
    is $mech->status, 401, "Bounced to login";
    ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
       "Found login form");
    is $mech->uri->path, '/aggregate/manage';
    my $node = $site->nodes->find_by_uri('pallino');
    $mech->get_ok('/node');
    $mech->content_contains('<option value="pallino">') or die $mech->content;
    $mech->get_ok('/node/pallino?bare=1');
    $mech->content_contains(q{href="/series/fmx"});
    $mech->content_contains(q{href="/aggregation/fmx-2"});
    $mech->content_lacks('<option value="pallino">', "Not offering to create a child from itself");
    $mech->content_contains('<option value="0">');
    $mech->submit_form(with_fields => {
                                       canonical_title => "Collection Pinco & Pallino <em>",
                                       attached_uris => "/series/fmx /aggregation/antology /library/to-test-one",
                                      },
                       button => 'update',
                      );
    $mech->get_ok('/node/pallino?bare=1');
    $mech->content_lacks('Pallino <em>');
    $mech->content_contains('Collection Pinco &amp; Pallino &lt;em&gt;');
    $node->discard_changes;
    is $node->aggregations->first->aggregation_uri, 'antology';
    is $node->aggregation_series->first->aggregation_series_uri, 'fmx';
    $mech->content_contains(q{href="/series/fmx"});
    $mech->content_lacks(q{href="/aggregation/fmx-2"});
    $mech->content_contains(q{href="/aggregation/antology"});
    ok $mech->follow_link(url_regex => qr{/bookbuilder/bulk/node/});
    is $mech->uri->path, '/node/pallino';
    $mech->content_contains('The texts were added to the bookbuilder');
    ok $mech->follow_link(url_regex => qr{/node\?node=pallino});
    $mech->content_contains(q{<option value="pallino" selected="selected">});
    $mech->submit_form(with_fields => {
                                       uri => 'Child Node',
                                       canonical_title => 'Child node',
                                       attached_uris => "/aggregation/fmx-2",
                                      });
    is $mech->uri->path, '/node/pallino/child-node';
    $mech->content_contains('For Marco #2');
    ok $mech->follow_link(url_regex => qr{/action/text/new\?node=});
    $mech->content_contains('selected="selected">Collection Pinco &amp; Pallino &lt;em&gt; / Child node<');
    $mech->submit_form(with_fields => {
                                       title => 'New Text In Collection',
                                       author => "Pippo",
                                      },
                       button => 'go',
                      );
    my $title = $site->titles->by_uri('pippo-new-text-in-collection')->first;
    ok $title, "Title created";
    ok $title->nodes->count, "It already has nodes";
}

{
    $mech->get_ok('/aggregate/manage');
    $mech->get_ok('/aggregate/series');
    $mech->submit_form(with_fields => {
                                       aggregation_series_uri => 'Serie <em> Pallino </em>',
                                       aggregation_series_name => 'Serie <em>Pallino</em>',
                                       publication_place => '<em>"test" & "test"</em>',
                                       publisher => '<em>Test<b>',
                                      },
                       button => 'update_button');
    is $mech->uri->path, '/series/serie-em-pallino-em';
    $mech->content_contains('<strong>Publication Place:</strong> &lt;em&gt;&quot;test&quot; &amp; &quot;test&quot;&lt;/em&gt;');
    $mech->content_contains('<strong>Publisher:</strong> &lt;em&gt;Test&lt;b&gt;');
    $mech->content_lacks('<em>Pallino</em>');
    $mech->content_contains('Serie &lt;em&gt;Pallino&lt;/em&gt;');

    ok $mech->follow_link(url_regex => qr{aggregate/edit\?series=});
    $mech->content_contains('name="aggregation_series_uri" value="serie-em-pallino-em"');

    # TODO go back and try the other button (and create)


    $mech->submit_form(with_fields => {
                                       aggregation_uri => 'NEW Aggregation',
                                       issue => '#3',
                                       sorting_pos => 1,
                                      },
                       button => 'update_button',
                      );
    is $mech->uri->path, '/aggregation/new-aggregation';

    # inherited from the series:
    $mech->content_contains('<strong>Publication Place:</strong> &lt;em&gt;&quot;test&quot; &amp; &quot;test&quot;&lt;/em&gt;');
    $mech->content_contains('<strong>Publisher:</strong> &lt;em&gt;Test&lt;b&gt;');
    $mech->content_lacks('<em>Pallino</em>');
    $mech->content_contains('Serie &lt;em&gt;Pallino&lt;/em&gt;');

    # TODO now try the other button (and create)

    # Test the create text
}
