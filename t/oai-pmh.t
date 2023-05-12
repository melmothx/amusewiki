#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};


use XML::Writer;
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

my $writer = XML::Writer->new(OUTPUT => 'self',
                              DATA_INDENT => 2,
                              ENCODING => 'utf-8',
                              DATA_MODE => 1);
$writer->xmlDecl;
$writer->startTag("Container");
$writer->dataElement('dc:test', 'testà');
$writer->dataElement('dc:test', 'testć');
$writer->endTag;
$writer->end;
diag "$writer";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0oai0';
my $site = create_site($schema, $site_id);
$site->update({ pdf => 1, a4_pdf => 1 });
$site->check_and_update_custom_formats;



my $oai_pmh = AmuseWikiFarm::Archive::OAI::PMH->new(site => $site);
ok $oai_pmh;

{
    my $muse = path($site->repo_root, qw/t tt to-test.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#author My author
#title Test me
#topics One topic; And another;
#lang ru
#attach shot.pdf

Все смешалось в доме Облонских. Жена узнала, что муж был в связи с
бывшею в их доме француженкою-гувернанткой, и объявила мужу, что не
может жить с ним в одном доме. Положение это продолжалось уже третий
день и мучительно чувствовалось и самими супругами, и всеми членами
семьи, и домочадцами. Все члены семьи и домочадцы чувствовали, что нет
смысла в их сожительстве и что на каждом постоялом дворе случайно
сошедшиеся люди более связаны между собой, чем они, члены семьи и
домочадцы Облонских. Жена не выходила из своих комнат, мужа третий
день не было дома. Дети бегали по всему дому, как потерянные;
англичанка поссорилась с экономкой и написала записку приятельнице,
прося приискать ей новое место; повар ушел еще вчера со двора, во
время обеда; черная кухарка и кучер просили расчета. 

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

$oai_pmh->update_site_records;

{
    ok $site->oai_pmh_records->search({ attachment_id => { '>', 0 } })->count, "Has attachments";
    ok $site->oai_pmh_records->search({ title_id => { '>', 0 } })->count, "Has texts";
    # check if they have all the fields
    foreach my $f (qw/metadata_format metadata_type metadata_identifier datestamp/) {
        ok !$site->oai_pmh_records->search({ $f => [ undef, '' ] })->count, "No records without $f";
    }
}

done_testing;
