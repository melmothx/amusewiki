#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Data::Dumper;
use Test::More tests => 233;
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

my $root = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$root->get_ok('/login');
ok $root->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

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

    $mech->get_ok('/annotation/download/' . $title->id . '/' .
                  $annotation_types{file}->annotation_id . '/whatever');

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
    $mech->get('/annotation/download/' . $title->id . '/' .
               $annotation_types{file}->annotation_id . '/whatever');
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
