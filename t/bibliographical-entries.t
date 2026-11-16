#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
};

use Test::More tests => 54;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use AmuseWikiFarm::Archive::CatalogSpreadsheet;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0biblioentry0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
ok ($site);
diag Dumper($site->spreadsheet_catalog_specification);
$mech->get('/console/upload-catalog-spreadsheet');
is $mech->status, 401;
ok $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' }), "Logged in";
$mech->get_ok('/console/upload-catalog-spreadsheet');
$mech->get_ok('/console/download-catalog-spreadsheet');
diag $mech->content;


# we want an export/import here. So they do the first upload with
# their sheet and they can get it back converted. Also good for
# backup.

my $cs = AmuseWikiFarm::Archive::CatalogSpreadsheet->new(site => $site);
ok $cs;

my $current;
foreach my $ext (qw/csv xls xlsx/) {
    my $records = $cs->get_records(catfile(t => files => 'catalog-sample.' . $ext));
    ok $records->[0]->{title} or die Dumper($records) . " Missing title in records";
    if ($current) {
        is_deeply($records, $current);
    }
    else {
        diag Dumper($records);
    }
    $current = $records;
}

{
    my $specification = $site->spreadsheet_catalog_specification;
    foreach my $spec (@$specification) {
        if ($spec->{name} =~ /title/) {
            $spec->{column} = 'x' . $spec->{name};
        }
        else {
            $spec->{column} = $spec->{name};
        }
        if ($spec->{separator}) {
            $spec->{separator} = '|';
        }
    }
    diag Dumper($specification);
    my $csx = AmuseWikiFarm::Archive::CatalogSpreadsheet->new(site => $site,
                                                              specification => $specification,
                                                             );
    diag Dumper($current);
    is_deeply $csx->get_records(catfile(t => files => 'catalog-sample-altered.csv')), $current;
    my $file = catfile(t => files => 'catalog-sample-altered.csv');
    my $bulk = $csx->create_revisions_from_file($file,
                                                {
                                                 logger => sub { diag @_ },
                                                });
    ok $bulk;
    my $total_jobs = $bulk->jobs->count;
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $mech->get_ok('/logout');
    foreach my $r (@$current) {
        $mech->get_ok('/library/' . $r->{uri});
    }
    $bulk = $csx->create_revisions_from_file($file,
                                             {
                                              logger => sub { diag @_ },
                                             });
    ok $bulk;
    is $bulk->jobs->count, $total_jobs, "Reimport the sheet spawned same number of jobs";
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    # now we pick one and add some text, another and we add an
    # attachment. Now the reimport would fail on those.
    my ($t1, $t2, $t3) = $site->titles->search(undef, { rows => 3 })->all;
    my @lacking;
    my @expected = map { $_->full_uri } ($t1, $t2, $t3);
    {
        my $rev = $t1->new_revision;
        my $got = $rev->add_attachment(catfile(qw/t files shot.pdf/));
        $rev->edit("#attach $got->{attachment}\n" . $rev->muse_body);
        $rev->commit_version;
        $rev->publish_text;
        my $att = $t1->discard_changes->attachments->first;
        $att->edit(title_muse => 'Test Attachment');
        push @expected, $att->full_uri;
        push @lacking, map { $t1->full_uri . $_ } ('.tex', '.epub', '.muse', '.zip');
    }
    {
        my $rev = $t2->new_revision;
        $rev->edit($rev->muse_body . "\n\nTest Body\n");
        $rev->commit_version;
        $rev->publish_text;
        push @expected, map { $t2->full_uri . $_ } ('.tex', '.epub', '.muse', '.zip');
    }
    {
        my $rev = $t3->new_revision;
        my $got = $rev->add_attachment(catfile(qw/t files shot.pdf/));
        $rev->edit("#attach $got->{attachment}\n" . $rev->muse_body);
        $rev->commit_version;
        $rev->publish_text;
        # attachment without a description won't get the entry
        push @lacking, map { $t3->full_uri . $_ } ('.tex', '.epub', '.muse', '.zip');
        push @lacking, $t3->discard_changes->attachments->first->full_uri;
    }
    $bulk = $csx->create_revisions_from_file($file,
                                             {
                                              logger => sub { diag @_ },
                                             });
    ok $bulk;
    is $bulk->jobs->count, $total_jobs - 3, "Reimport the sheet spawned 3 jobs less";
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $mech->get_ok('/oai-pmh?verb=ListRecords&metadataPrefix=marc21&set=web');
    diag $mech->content;
    foreach my $str (@lacking) {
        $mech->content_lacks($str);
    }
    foreach my $str (@expected) {
        $mech->content_contains($str);
    }
}
