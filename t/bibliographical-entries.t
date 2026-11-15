#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
};

use Test::More tests => 34;
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
    my $total_jobs = 0;
    while (my $j = $site->jobs->dequeue) {
        $total_jobs++;
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
    while (my $j = $site->jobs->dequeue) {
        $total_jobs--;
        $j->dispatch_job;
        diag $j->logs;
    }
    ok !$total_jobs, "Reimport the sheet spawned same number of jobs";

}
