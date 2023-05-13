#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};


use Data::Dumper;
use Test::More;
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
foreach my $att ($site->attachments) {
    $att->edit(
               title_muse => $att->uri, 
               comment_muse => $att->uri . " *comment*",
               alt_text => $att->uri . " description ",
              );
}

for (1..2) {
    $oai_pmh->update_site_records;
    ok $site->oai_pmh_records->search({ attachment_id => { '>', 0 } })->count, "Has attachments";
    ok $site->oai_pmh_records->search({ title_id => { '>', 0 } })->count, "Has texts";
    # check if they have all the fields
    foreach my $f (qw/metadata_format metadata_type metadata_identifier datestamp/) {
        ok !$site->oai_pmh_records->search({ $f => [ undef, '' ] })->count, "No records without $f";
    }
    ok !$site->oai_pmh_records->search({ deleted => 1 })->count, "No deleted records";
    sleep 2;
}

foreach my $rec ($site->oai_pmh_records) {
    is $rec->datestamp->time_zone->name, 'UTC';
    $mech->get_ok($rec->metadata_identifier);
}

{
    ok path($site->repo_root, qw/t tt to-test.a4.pdf/)->remove;
    $oai_pmh->update_site_records;
    is $site->oai_pmh_records->search({ deleted => 1 })->count, 1, "Found the deletion";
}

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
                             ],
                  },
                  {
                   args => {
                            verb => 'GetRecord',
                            metadataPrefix => 'oai_dc',
                            identifier => $site->oai_pmh_records->search({
                                                                          title_id => { '>', 0 },
                                                                          identifier => { -like => '%.pdf' },
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
                                                                          identifier => { -like => '%.muse' },
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
                              '<dc:title>t-t-1.png description</dc:title>',
                              '<setSpec>amusewiki</setSpec>',
                              '<dc:format>image/png</dc:format>',
                              '<dc:type>image</dc:type>',
                             ],
                  },
                 ) {
    my $uri = URI->new($site->canonical_url);
    $uri->path('/oai-pmh');
    $uri->query_form($test->{args});
    $mech->get_ok("$uri");
    diag $mech->content;
    foreach my $exp (@{$test->{expect}}) {
        $mech->content_contains($exp);
    }
    foreach my $lacks (@{$test->{lacks} || []}) {
        $mech->content_lacks($lacks);
    }

}


done_testing;
