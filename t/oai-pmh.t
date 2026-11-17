#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
    $ENV{AMW_OAI_PMH_PAGE_SIZE} = 8;
};


use Data::Dumper;
use Test::More tests => 240;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::OAI::PMH;
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
my $site_id = '0oai0';
my $site = create_site($schema, $site_id);
$site->update({ pdf => 1, a4_pdf => 1 });
$site->check_and_update_custom_formats;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


my $oai_pmh = AmuseWikiFarm::Archive::OAI::PMH->new(site => $site,
                                                    oai_pmh_url => URI->new($site->canonical_url . '/oai-pmh'));
ok $oai_pmh;
diag $oai_pmh->process_request;
diag $oai_pmh->process_request({ verb => 'Identify' });
diag $oai_pmh->process_request({ verb => 'ListMetadataFormats' });
$site->oai_pmh_sets->delete;
diag $oai_pmh->process_request({ verb => 'ListSets' });

diag $oai_pmh->process_request({
                                verb => 'GetRecord',
                                identifier => 'oai:0oai0.amusewiki.org:/library/to-test.muse',
                                metadataPrefix => 'oai_dc',
                               });

{
    my $set = $site->oai_pmh_sets->create({
                                           set_spec => 'test',
                                           set_name => 'Test',
                                          });
    diag $oai_pmh->process_request({ verb => 'ListSets' });
    $set->delete;
}


{
    my $muse = path($site->repo_root, qw/t tt to-test.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#author My author
#title Test me
#authors One <author>; and & anotherrxx
#source From "the" internet
#rights No <copycat>
#topics One topic; And <another>; xAnd&another;
#lang it
#attach shot.pdf
#publisher <testing> publisher
#date 1923 and something else
#datefirst 1888 and something else
#subtitle This is a subtitle
#teaser This is the teaser
#notes These are the notes
#isbn 8790000000000

> Tirsi morir volea,
> Gl'occhi mirando di colei ch'adora;
> Quand'ella, che di lui non meno ardea,
> Gli disse: "Ahimè, ben mio,
> Deh, non morir ancora,
> Che teco bramo di morir anch'io."
>
> Frenò Tirsi il desio,
> Ch'ebbe di pur sua vit'allor finire;
> Ma (E) sentea morte,in (e) non poter morire.
> E mentr'il guardo suo fisso tenea
> Ne' begl'occhi divini
> E'l nettare amoroso indi bevea,
>
> La bella Ninfa sua, che già vicini
> Sentea i messi d'Amore,
> Disse, con occhi languidi e tremanti:
> "Mori, cor mio, ch'io moro."
> Cui rispose il Pastore:
> "Ed io, mia vita, moro."
>
> Cosi moriro i fortunati amanti
> Di morte si soave e si gradita,
> Che per anco morir tornaro in vita.

[[t-t-1.png]]

[[t-t-2.jpeg]]

MUSE

    path(t => files => 'shot.pdf')->copy(path($site->repo_root, 'uploads', 'shot.pdf'));
    path(t => files => 'shot.png')->copy(path($site->repo_root, qw/t tt t-t-1.png/));
    path(t => files => 'shot.jpg')->copy(path($site->repo_root, qw/t tt t-t-2.jpeg/));
    my $child = path($site->repo_root, qw/t tt t-t-child.muse/);

    $child->spew_utf8(<<"MUSE");
#title Sub text
#source From "the" internet
#date 1923 and something else
#subtitle This is a subtitle
#parent to-test

This is the body of the child
MUSE
    $site->git->add('uploads');
    $site->git->add('t');
    $site->git->commit({ message => "Added files" });
}

diag "Updating DB from tree";
$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}
if (my $att = $site->attachments->find({ uri => 't-t-1.png' })) {
    $att->edit(
               title_muse => $att->uri . " *title*",
               comment_muse => $att->uri . " *comment*",
               alt_text => $att->uri . " description ",
              );
}

for (1..2) {
    $oai_pmh->update_site_records;
    ok $site->oai_pmh_records->search({ attachment_id => { '>', 0 } })->count, "Has attachments";
    ok $site->oai_pmh_records->search({ title_id => { '>', 0 } })->count, "Has texts";
    # check if they have all the fields
    foreach my $f (qw/metadata_format metadata_type datestamp/) {
        ok !$site->oai_pmh_records->search({ $f => [ undef, '' ] })->count, "No records without $f";
    }
    ok !$site->oai_pmh_records->search({ deleted => 1 })->count, "No deleted records";
    sleep 2;
}



foreach my $rec ($site->oai_pmh_records) {
    is $rec->datestamp->time_zone->name, 'UTC';
    $mech->get_ok($site->canonical_url . $rec->identifier);
    ok $rec->identifier, "Identifier is fine" . $rec->identifier;
}

{
    ok path($site->repo_root, qw/t tt to-test.a4.pdf/)->remove;
    $oai_pmh->update_site_records;
    is $site->oai_pmh_records->search({ deleted => 1 })->count, 1, "Found the deletion";
}

my $latest_ts = $site->oai_pmh_records->search(undef, { order_by => { -desc => 'datestamp' } })->first->zulu_datestamp;

# make up a resumption token
my $resumption_token = $oai_pmh->encode_resumption_token({
                                                          metadataPrefix => 'oai_dc',
                                                          from => $latest_ts,
                                                          until => $latest_ts,
                                                          done_so_far => 9, # made up
                                                          total => 10, # made up
                                                          set => '',
                                                         })->[2];
ok $resumption_token, "Resumption toke is fine";

foreach my $test ({
                   args => {},
                   expect => [
                              '<request>https://0oai0.amusewiki.org/oai-pmh</request>',
                              '<error code="badVerb">Bad verb: MISSING</error>',
                             ],
                  },
                  {
                   args => { verb => 'GetRecord' },
                   expect => [
                              '<error code="badArgument">',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                           },
                   expect => [
                              '<error code="badArgument">',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'X',
                           },
                   expect => [
                              '<error code="badArgument">',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'X',
                            identifier => 'X'
                           },
                   expect => [
                              '<error code="cannotDisseminateFormat">',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'X',
                            identifier => 'X'
                           },
                   expect => [
                              '<error code="cannotDisseminateFormat">',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => 'X'
                           },
                   expect => [
                              '<error code="idDoesNotExist">',
                             ],
                  },
                  {
                   args => {
                            verb => 'Pippo',
                           },
                   expect => [
                              '<error code="badVerb">Bad verb: Pippo</error>',
                             ],
                  },
                  {
                   args => {
                            verb => 'Identify',
                           },
                   expect => [
                              '<request verb="Identify">https://0oai0.amusewiki.org/oai-pmh</request>'
                             ],
                  },
                  {
                   args => {
                            verb => 'ListMetadataFormats',
                           },
                   expect => [
                              '<metadataNamespace>http://www.openarchives.org/OAI/2.0/oai_dc/</metadataNamespace>',
                              '<metadataPrefix>oai_dc</metadataPrefix>',
                              '<request verb="ListMetadataFormats">https://0oai0.amusewiki.org/oai-pmh</request>',
                             ]
                  },
                  {
                   args => {
                            verb => 'ListSets',
                           },
                   expect => [
                              '<request verb="ListSets">https://0oai0.amusewiki.org/oai-pmh</request>',
                              '<setSpec>amusewiki</setSpec>',
                              '<setName>Files needed to regenerate the archive</setName>',
                              '<setSpec>web</setSpec>',
                              '<setName>Links to web pages</setName>',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({
                                                                          title_id => { '>', 0 },
                                                                          identifier => { -like => '%to-test%.pdf' },
                                                                         })->first->identifier,
                           },
                   expect => [
                              '<dc:title>Test me</dc:title>',
                              '<dc:title>This is a subtitle</dc:title>',
                              '<dc:creator>One &lt;author&gt;</dc:creator>',
                              '<dc:creator>and &amp; anotherrxx</dc:creator>',
                              '<dc:subject>One topic</dc:subject>',
                              '<dc:subject>And &lt;another&gt;</dc:subject>',
                              '<dc:subject>xAnd&amp;another</dc:subject>',
                              '<dc:publisher>&lt;testing&gt; publisher</dc:publisher>',
                              '<dc:date>1888</dc:date>',
                              '<dc:date>1923</dc:date>',
                              '<dc:source>From "the" internet</dc:source>',
                              '<dc:language>it</dc:language>',
                              '<dc:rights>No &lt;copycat&gt;</dc:rights>',
                              '<dc:type>text</dc:type>',
                              '<dc:format>application/pdf</dc:format>',
                             ],
                   lacks => [
                             '<setSpec>amusewiki</setSpec>'
                            ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({
                                                                          title_id => { '>', 0 },
                                                                          identifier => { -like => '%to-test%.muse' },
                                                                         })->first->identifier,
                           },
                   expect => [
                              '<dc:title>Test me</dc:title>',
                              '<dc:creator>One &lt;author&gt;</dc:creator>',
                              '<dc:creator>and &amp; anotherrxx</dc:creator>',
                              '<dc:subject>One topic</dc:subject>',
                              '<dc:subject>And &lt;another&gt;</dc:subject>',
                              '<dc:subject>xAnd&amp;another</dc:subject>',
                              '<dc:publisher>&lt;testing&gt; publisher</dc:publisher>',
                              '<dc:date>1923</dc:date>',
                              '<dc:source>From "the" internet</dc:source>',
                              '<dc:language>it</dc:language>',
                              '<dc:rights>No &lt;copycat&gt;</dc:rights>',
                              '<setSpec>amusewiki</setSpec>',
                              '<dc:format>text/plain</dc:format>',
                              '<dc:type>text</dc:type>',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({ attachment_id => { '>', 0 } })->first->identifier,
                           },
                   expect => [
                              '<dc:title>t-t-1.png title</dc:title>',
                              '<setSpec>amusewiki</setSpec>',
                              '<dc:format>image/png</dc:format>',
                              '<dc:type>image</dc:type>',
                              '<dc:relation>https://0oai0.amusewiki.org/library/to-test</dc:relation>',
                             ],
                   lacks => [
                             '<header status="deleted">',
                            ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({
                                                                          deleted => 1,
                                                                         })->first->identifier,
                           },
                   expect => [
                              '<header status="deleted">',
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'marc21',
                            identifier => $site->oai_pmh_records->search({
                                                                          deleted => 1,
                                                                         })->first->identifier,
                           },
                   expect => [
                              '<header status="deleted">',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            set => 'amusewiki',
                           },
                   expect => [
                              'to-test.muse</identifier>',
                              '<setSpec>amusewiki</setSpec>',
                              '/uploads/0oai0/shot.pdf</identifier>',
                              '<dc:identifier>https://0oai0.amusewiki.org/uploads/0oai0/shot.pdf</dc:identifier>'
                             ],
                   lacks => [
                             'to-test.pdf</identifier>',
                            ]
                  },
                  {
                   args => {
                            verb => 'ListIdentifiers',
                            metadataPrefix => 'oai_dc',
                            set => 'amusewiki',
                           },
                   expect => [
                              '/to-test.muse</identifier>',
                              '<setSpec>amusewiki</setSpec>',
                              '/uploads/0oai0/shot.pdf</identifier>',
                             ],
                   lacks => [
                             '/to-test</identifier>',
                             'to-test.pdf</identifier>',
                            ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            until => DateTime->now->add(days => 1)->ymd,
                           },
                   expect => [
                              '<error code="badArgument">The date for until is in the future!</error>',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            until => DateTime->now->add(days => 1)->ymd . 'x',
                           },
                   expect => [
                              '<error code="badArgument">Invalid until format</error>',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            from => DateTime->now->add(days => 1)->ymd . 'x',
                           },
                   expect => [
                              '<error code="badArgument">Invalid from format</error>',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListIdentifiers',
                            metadataPrefix => 'oai_dc',
                           },
                   expect => [
                              'to-test.pdf</identifier>',
                              '<resumptionToken completeListSize="18" cursor="0">',
                             ],
                   lacks => [
                             'to-test.a4.pdf</identifier>',
                              '<resumptionToken completeListSize="18" cursor="9" />',
                            ],

                  },
                  {
                   args => {
                            verb => 'ListIdentifiers',
                            resumptionToken => $resumption_token,
                           },
                   expect => [
                              'to-test.a4.pdf</identifier>',
                              '<resumptionToken completeListSize="10" cursor="9" />',
                             ],
                   lacks => [
                             'to-test.pdf</identifier>',
                              '<resumptionToken completeListSize="10" cursor="0">',
                            ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                           },
                   expect => [
                              'to-test.pdf</identifier>',
                              '<dc:description>Plain PDF</dc:description>',
                              '<resumptionToken completeListSize="18" cursor="0">',
                             ],
                   lacks => [
                             'to-test.a4.pdf</identifier>',
                              '<resumptionToken completeListSize="18" cursor="9" />',
                            ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            resumptionToken => $resumption_token,
                           },
                   expect => [
                              'to-test.a4.pdf</identifier>',
                              '<dc:description>A4 imposed PDF</dc:description>',
                              '<dc:description>This is the teaser</dc:description>',
                              '<dc:description>These are the notes</dc:description>',
                              '<resumptionToken completeListSize="10" cursor="9" />',
                             ],
                   lacks => [
                             'to-test.pdf</identifier>',
                              '<resumptionToken completeListSize="10" cursor="0">',
                            ],

                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            from => DateTime->today->ymd,
                            until => DateTime->today->ymd,
                           },
                   expect => [
                              'to-test.pdf</identifier>',
                              '<resumptionToken completeListSize="18" cursor="0">',
                             ],
                   lacks => [
                             '<error code="noRecordsMatch">',
                            ],
                  },
                  {
                   args => {
                            verb => 'ListIdentifiers',
                            metadataPrefix => 'oai_dc',
                            from => DateTime->today->subtract(years => 1)->ymd,
                            until => DateTime->today->subtract(years => 1)->ymd,
                           },
                   expect => [
                             '<error code="noRecordsMatch">',
                             ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'marc21',
                            from => DateTime->today->ymd,
                            until => DateTime->today->ymd,
                           },
                   expect => [
                              'to-test.pdf</identifier>',
                              '<resumptionToken completeListSize="18" cursor="0">',
                              '<leader>      am         3u     </leader>',
                              '<datafield tag="246" ind1="3" ind2="3">',
                              '<subfield code="a">This is a subtitle</subfield>',
                             ],
                   lacks => [
                             '<error code="noRecordsMatch">',
                             '<subfield code="a" />',
                            ],
                   re => [
                          qr{<datafield tag="100" ind1="0" ind2=" ">\s*<subfield code="a">.*?</subfield>\s*<subfield code="e">author</subfield>}si,
                          qr{<datafield tag="856" ind1=" " ind2=" ">\s*<subfield code="u">.*?</subfield>\s*<subfield code="q">.*?</subfield>\s*<subfield code="y">.*?</subfield>}
                         ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'marc21',
                            identifier => '/library/to-test.pdf',
                           },
                   expect => [
                              'to-test.pdf</identifier>',
                              '<leader>      am         3u     </leader>',
                              '<datafield tag="246" ind1="3" ind2="3">',
                              '<subfield code="a">This is a subtitle</subfield>',
                             ],
                   lacks => [
                             '<error code="cannotDisseminateFormat">',
                             '<subfield code="a" />',
                            ],
                  },
                  {
                   args => {
                            verb => 'ListRecords',
                            metadataPrefix => 'oai_dc',
                            set => 'web',
                           },
                   expect => [
                              '/library/to-test</identifier>',
                              '<setSpec>web</setSpec>',
                              '<dc:identifier>https://0oai0.amusewiki.org/library/to-test</dc:identifier>'
                             ],
                   lacks => [
                             'to-test.html</identifier>',
                             'to-test.pdf</identifier>',
                              '/uploads/0oai0/shot.pdf</identifier>',
                            ]
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({
                                                                          title_id => { '>', 0 },
                                                                          identifier => { -like => '%child%.epub' },
                                                                         })->first->identifier,
                           },
                   expect => [
                              '<dc:description>EPUB (for mobile devices)</dc:description>',
                              '<dc:relation>https://0oai0.amusewiki.org/library/to-test</dc:relation>',
                             ],
                   lacks => [
                              '<dc:description>-</dc:description>',
                            ],
                  },
                 ) {
    my $uri = URI->new($site->canonical_url);
    $uri->path('/oai-pmh');
    if ($test->{args}->{identifier}) {
        $test->{args}->{identifier} = $site->oai_pmh_base_identifier . $test->{args}->{identifier}
    }
    $uri->query_form($test->{args});
    $mech->get_ok("$uri") or die;
    diag $mech->content;
    foreach my $re (@{$test->{re} || []}) {
        $mech->content_like($re);
    }
    foreach my $exp (@{$test->{expect}}) {
        $mech->content_contains($exp);
    }
    foreach my $lacks (@{$test->{lacks} || []}) {
        $mech->content_lacks($lacks);
    }
}

ok $site->oai_pmh_records->oldest_record;

sleep 2;
my $now;


{
    my $muse = path($site->repo_root, qw/t tx testxx.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#title Test XX
#lang en

[[t-x-1.png]]

Test
MUSE
    my $att = path($site->repo_root, qw/t tx t-x-1.png/);
    path(t => files => 'shot.png')->copy(path($att));
    $site->update_db_from_tree;
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    ok $site->oai_pmh_records->find({ identifier => '/library/testxx' });
    ok $site->oai_pmh_records->find({ identifier => '/library/t-x-1.png' });

    sleep 2;
    $att->remove;
    $muse->remove;
    # we are going to ask the records since the removal
    $now = DateTime->now;
    $site->update_db_from_tree;
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    is $site->oai_pmh_records->find({ identifier => '/library/testxx' })->deleted, 1;
    is $site->oai_pmh_records->find({ identifier => '/library/t-x-1.png' })->deleted, 1;
    sleep 2;
}

foreach my $prefix (qw/oai_dc marc21/){
    $mech->get_ok(qq{/oai-pmh?verb=GetRecord&identifier=oai%3A0oai0.amusewiki.org%3A%2Flibrary%2Ftestxx&metadataPrefix=$prefix});
    diag $mech->content;
    if ($prefix eq 'oai_dc') {
        $mech->content_contains('<dc:title>Removed entry</dc:title>');
        $mech->content_contains('<dc:description>This entry was deleted</dc:description>');
    }
    else {
        $mech->content_contains('<subfield code="a">Removed entry<');
        $mech->content_contains('<subfield code="a">This entry was deleted<');
    }
    $mech->content_contains('<header status="deleted">');

    my $uri = URI->new($site->canonical_url);
    $uri->path('/oai-pmh');
    $uri->query_form({ from => $now->iso8601 . 'Z', metadataPrefix => $prefix, verb => 'ListRecords' });
    $mech->get_ok($uri);
    my $xml = $mech->content;
    my @identifiers;
    while ($xml =~ m{<identifier>(.*)</identifier>}g) {
        push @identifiers, $1;
    }
    ok scalar(grep { $_ eq 'oai:0oai0.amusewiki.org:/library/testxx', } @identifiers);
    ok scalar(grep { $_ eq 'oai:0oai0.amusewiki.org:/library/t-x-1.png', } @identifiers);
    diag Dumper(\@identifiers);
}

is $site->oai_pmh_records->find({ identifier => '/library/to-test.a4.pdf' })->deleted, 1;
sleep 1;
path($site->repo_root, qw/t tt to-test.a4.pdf/)->spew_raw("test");
$oai_pmh->update_site_records;
is $site->oai_pmh_records->find({ identifier => '/library/testxx' })->deleted, 1;
is $site->oai_pmh_records->find({ identifier => '/library/to-test.a4.pdf' })->deleted, 0;

