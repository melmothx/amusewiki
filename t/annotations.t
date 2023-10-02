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

