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
# let's use the blog one

my $site = $schema->resultset('Site')->find('0blog0');
my $oai_pmh = AmuseWikiFarm::Archive::OAI::PMH->new(site => $site);
ok $oai_pmh;
