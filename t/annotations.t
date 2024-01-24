#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 254;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use URI;

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

my $root = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$root->get_ok('/login');
ok $root->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

foreach my $title (qw/one two tree/) {
    my $muse = path($site->repo_root, qw/t tt/, "to-test-$title.muse");
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#authors Author $title; Authors $title; Pinco, Pallino
#title Title $title
#topics First $title; Second #title
#lang en
#author My author
#source From "the" internet
#rights No <copycat>
#publisher <testing> publisher
#date 1923 and something else
#datefirst 1888 and something else
#subtitle This is a subtitle
#teaser This is the *teaser*
#notes These **are** the notes
#isbn 8790000000000
#sku bib12341234

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
                                             label => "Original",
                                             annotation_name => "original",
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
$annotation->delete;

my %annotation_types;

foreach my $type (qw/identifier text file/) {
    my $ann = $site->annotations->create({
                                          label => ucfirst($type),
                                          annotation_name => $type,
                                          annotation_type => $type,
                                         });
    $annotation_types{$type} = $ann;
}

foreach my $title ($site->titles->all) {
    my %update;
    foreach my $ann ($site->annotations) {
        $update{$ann->annotation_id} = {
                                        value => $ann->label . " Test",
                                       };
        if ($ann->annotation_type eq 'file') {
            $update{$ann->annotation_id}{file} = 't/files/shot.pdf';
        }
    }
    my $res = $title->annotate(\%update);

    # check if the file was written
    ok -f "repo/" . $site->id . "/annotations/file/text/" .
      $title->f_archive_rel_path . "/" . $title->uri . '.pdf';

    ok $res->{success} or diag Dumper($res);
    is $title->title_annotations->count, 3;

    foreach my $up (values %update) {
        $up->{value} .= " x";
    }
    $res = $title->annotate(\%update);
    is $title->title_annotations->count, 3;

    $mech->get_ok(join('/', '/annotation/download',
                       $annotation_types{file}->annotation_id,
                       $title->f_class,
                       $title->uri,
                       'whatever'));

    # this is for librarians only
    $mech->get('/annotate/title/' . $title->id);
    is $mech->status, 401;

    $site->annotations->update({
                                private => 0,
                                active => 1,
                               });
    $mech->get_ok($title->full_uri);
    $mech->content_contains('Identifier Test x');
    $mech->content_contains('Text Test x');


    $root->get_ok($title->full_uri);
    $root->content_contains('Identifier Test x');
    $root->content_contains('Text Test x');

    foreach my $aoi ($title->oai_pmh_records) {
        my (@relevant) = grep { $_->[0] =~ m/dc:(identifier|description)/ } @{$aoi->dublin_core_record};
        is scalar(@relevant), 6, "Found 6 records for DC " . $relevant[4][1];
        is $relevant[5][1], "Identifier Test x";
        is $relevant[3][1], "Text: Text Test x";
    }
    $site->annotations->update({
                                private => 1,
                                active => 0,
                               });
    # inactive
    $mech->get_ok($title->full_uri);
    $mech->content_lacks('Identifier Test x');
    $mech->content_lacks('Text Test x');

    $root->get_ok($title->full_uri);
    $root->content_lacks('Identifier Test x');
    $root->content_lacks('Text Test x');


    foreach my $aoi ($title->oai_pmh_records) {
        my (@relevant) = grep { $_->[0] =~ m/dc:(identifier|description)/ } @{$aoi->dublin_core_record};
        is scalar(@relevant), 4, "Found 4 records for DC " . $relevant[3][1];
    }

    # inactive
    $site->annotations->update({
                                private => 0,
                                active => 0,
                               });
    $mech->get_ok($title->full_uri);
    $mech->content_lacks('Identifier Test x');
    $mech->content_lacks('Text Test x');

    $root->get_ok($title->full_uri);
    $root->content_lacks('Identifier Test x');
    $root->content_lacks('Text Test x');


    foreach my $aoi ($title->oai_pmh_records) {
        my (@relevant) = grep { $_->[0] =~ m/dc:(identifier|description)/ } @{$aoi->dublin_core_record};
        is scalar(@relevant), 4, "Found 4 records for DC " . $relevant[3][1];
    }

    # active but private, so logged in can see/edit
    $site->annotations->update({
                                private => 1,
                                active => 1,
                               });
    $mech->get_ok($title->full_uri);
    $mech->content_lacks('Identifier Test x');
    $mech->content_lacks('Text Test x');

    $root->get_ok($title->full_uri);
    $root->content_contains('Identifier Test x');
    $root->content_contains('Text Test x');


    foreach my $aoi ($title->oai_pmh_records) {
        my (@relevant) = grep { $_->[0] =~ m/dc:(identifier|description)/ } @{$aoi->dublin_core_record};
        is scalar(@relevant), 4, "Found 4 records for DC " . $relevant[3][1];
    }

    # if we have a bad value in the db: do not serve it.
    $title->title_annotations->update({ annotation_value => '../../../../../../../../../../../etc/passwd' });
    $mech->get(join('/', '/annotation/download',
                    $annotation_types{file}->annotation_id,
                    $title->f_class,
                    $title->uri,
                    'whatever'));
    is $mech->status, 404;
    ok $res->{success} or diag Dumper($res);

    foreach my $up (values %update) {
        $up->{remove} = 1;
    }
    $res = $title->annotate(\%update);
    ok $res->{success} or diag Dumper($res);

    $res = $title->annotate({
                             $annotation_types{file}->annotation_id => {
                                                                        value => 'dummy',
                                                                        file => 'dummy',
                                                                       },
                            });
    ok $res->{errors};
    diag Dumper($res);
}

ok path($site->repo_root, 'annotations', '.gitignore')->exists;

# reinsert anew
{
    my %update;
    foreach my $ann ($site->annotations) {
        $ann->update({ private => 0, active => 1 });
        $update{$ann->annotation_id} = {
                                        value => $ann->label . " New Test",
                                       };
        if ($ann->annotation_type eq 'file') {
            $update{$ann->annotation_id}{file} = 't/files/shot.pdf';
        }
    }
    foreach my $title ($site->titles) {
        $_->{value} .= " " . $title->uri for values %update;
        my $res = $title->annotate(\%update);
        ok $res->{success};
    }
    foreach my $ann ($site->annotations) {
        ok $ann->title_annotations->count;
        $ann->title_annotations->delete;
        is $ann->title_annotations->count, 0, "Annotation cleared";
    }
    $site->import_annotations_from_tree({ logger => sub { diag @_ } });
    foreach my $ann ($site->annotations) {
        ok $ann->title_annotations->count;
    }
}
# test slc and price with oai-pmh
{
    my $ap = $site->annotations->create({
                                         label => 'Price',
                                         annotation_name => 'price',
                                         annotation_type => 'text'
                                        });
    my $as = $site->annotations->create({
                                         label => 'Shelf Location Code',
                                         annotation_name => 'slc',
                                         annotation_type => 'identifier'
                                        });
    my $title = $site->titles->first;
    diag $title->full_uri;
    $title->annotate({
                      $ap->annotation_id => { value => '30 EUR' },
                      $as->annotation_id => { value => 'YY/X' },
                     });
    $mech->get('/oai-pmh?verb=GetRecord&metadataPrefix=marc21&identifier=oai:0annotate0.amusewiki.org:' .
               $title->full_uri . '.epub');
    my $xml = $mech->content;
    # author with indicator for first last or last first
    like $xml, qr{tag="100" ind1="0" ind2=" ">\s*<subfield code="a">Author one}s;
    like $xml, qr{tag="100" ind1="1" ind2=" ">\s*<subfield code="a">Pinco, Pallino}s;
    # isbn
    like $xml, qr{tag="020" ind1=" " ind2=" ">\s*<subfield code="a">8790000000000}s;
    # dates
    like $xml, qr{tag="363" ind1=" " ind2=" ">\s*<subfield code="i">1888}s;
    like $xml, qr{tag="363" ind1=" " ind2=" ">\s*<subfield code="i">1923}s;
    #price
    like $xml, qr{tag="365" ind1=" " ind2=" ">\s*<subfield code="b">30}s;
    like $xml, qr{tag="365" ind1=" " ind2=" ">\s*<subfield code="c">EUR}s;
    # slc
    like $xml, qr{tag="852" ind1=" " ind2=" ">\s*<subfield code="c">YY/X}s;
    # uri
    like $xml, qr{tag="856"\sind1="\s"\sind2="\s">\s*
                  <subfield\s+ code="u">https://0annotate0.amusewiki.org/library/[\w-]+\.epub</subfield>
                  \s*
                  <subfield\scode="q">application/epub\+zip</subfield>
                  \s*
                  <subfield\scode="y">EPUB
             }sx;
    # sku
    like $xml, qr{tag="024" ind1="8" ind2=" ">\s*<subfield code="a">bib123}s;
    like $xml, qr{These are the notes}, "HTML cleaned";
    like $xml, qr{This is the teaser}, "HTML cleaned";
    diag $xml;
    # the dates
    my ($datestamp) = $xml =~ m/<datestamp>(.+)<\/datestamp>/;
    sleep 1;
    my $uri = URI->new($site->canonical_url);
    my $now = DateTime->now(time_zone => 'UTC');
    $uri->path('/oai-pmh');
    $uri->query_form({ from => $now->iso8601 . 'Z', metadataPrefix => 'oai_dc', verb => 'ListRecords' });
    $mech->get_ok($uri);
    $mech->content_contains('noRecordsMatch');
    sleep 1;
    $title->annotate({
                      $ap->annotation_id => { value => '300 EUR' },
                      $as->annotation_id => { value => 'YYx/Xx' },
                     });
    $mech->get_ok($uri);
    $mech->content_lacks('noRecordsMatch');
    $mech->content_contains('YYx/Xx');

    $now = DateTime->now(time_zone => 'UTC');
    sleep 1;
    $title->annotate({
                      $ap->annotation_id => { value => '' },
                      $as->annotation_id => { value => '' },
                     });
    $mech->get_ok($uri);
    $mech->content_lacks('noRecordsMatch');
    $mech->content_lacks('tag="852"') or diag $mech->content;
    $mech->content_lacks('tag="365"') or diag $mech->content;
}
