#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 26;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $orig = create_site($schema, '0federation3');
my $mirror = create_site($schema, '0federation4');
my $mech_orig = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    host => $orig->canonical);

my $mech_mirror = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                      host => $mirror->canonical);

$schema->resultset('Job')->delete;
$schema->resultset('BulkJob')->delete;
diag $mirror->repo_root;

{
    foreach my $title (qw/one two three/) {
        my $muse = path($orig->repo_root, qw/t tt/, "to-test-$title.muse");
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
    $orig->git->add('t');
    $orig->git->commit({ message => "Added files" });
    diag "Updating DB from tree";
    $orig->update_db_from_tree;
    is $orig->titles->count, 3;
}

{
    my $local_muse = path($mirror->repo_root, qw/t tt/, "to-test-pizza.muse");
    $local_muse->parent->mkpath;
    $local_muse->spew_utf8(<<"MUSE");
#title Local file
#lang en

Test

MUSE
    $mirror->git->add('t');
    $mirror->git->commit({ message => "Added files" });
    diag "Updating DB from tree";
    $mirror->update_db_from_tree;
    is $mirror->titles->count, 1;
}

$mirror->add_to_mirror_origins({
                                remote_domain => $orig->canonical,
                                remote_path => '/',
                                active => 1,
                               });
my $remote = $mirror->mirror_origins->first;
$remote->ua($mech_orig);
_fetch_remote($remote);
is $mirror->titles->count, 4, "Mirror OK";

# now let's remove one remote

{
    path($orig->repo_root, qw/t tt to-test-one.muse/)->remove;
    $orig->git->add('t');
    $orig->git->commit({ message => "Removed files" });
    diag "Updating DB from tree";
    $orig->update_db_from_tree;
    is $orig->titles->count, 2;
}

# and refetch

_fetch_remote($remote);
is $mirror->titles->count, 4, "Mirror OK";
$mirror->jobs->enqueue('purge_mirror_leftovers', {});
while (my $job = $mirror->jobs->dequeue) {
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
}
is $mirror->titles->count, 4, "Mirror intact";

$mirror->site_options->update_or_create({
                                         option_name => 'mirror_only',
                                         option_value => 1
                                        });

for (1..2) {
    $schema->resultset('Job')->enqueue_global_job('hourly_job');
    while (my $job = $schema->resultset('Job')->dequeue) {
        $job->dispatch_job;
        is $job->status, 'completed';
        diag $job->logs;
    }
    is $mirror->titles->count, 2, "Mirror purged because of the option";
}

sub _fetch_remote {
    my ($remote) = @_;
    my $res = $remote->fetch_remote;
    diag Dumper($res);
    ok $res->{data}, "Fetched remote";
    ok !$res->{error}, "No errors";
    my $bulk_job = $remote->prepare_download($res->{data});
    my $site = $remote->site;
    while (my $job = $site->jobs->dequeue) {
        $job->dispatch_job({ ua => $remote->ua });        
        is $job->status, 'completed';
        diag $job->logs;
    }
}

# keep the testing clean, breaks jobs.t

$mirror->delete;
$orig->delete;
