#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 7;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use AmuseWikiFarm::Utils::Jobber;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;

my $site = create_site($schema, '0cformats0');
$site->update({
               secure_site => 0,
               pdf => 0,
               a4_pdf => 0,
               sl_pdf => 0,
               lt_pdf => 0,
              });

$site->check_and_update_custom_formats;

{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    my $body = <<"MUSE";
#lang en
#author pinco
#title pallino

Bla bla

MUSE
    $rev->edit($body);
    $rev->commit_version;
    $rev->publish_text;
}

is $site->jobs->pending->count, 1;

ok $site->jobs->dequeue->dispatch_job;

$site->update({
               pdf => 1,
              });

$site->check_and_update_custom_formats;


$site->jobs->rebuild_add({ id => $site->titles->first->id });

ok $site->jobs->dequeue->dispatch_job;

is $site->jobs->pending->count, 2;

foreach my $j ($site->jobs->pending->all) {
    diag Dumper($j->as_hashref);
}

is $site->jobs->pending->search({ task => 'build_custom_format' })->count, 1;

my $j = $site->jobs->dequeue;
my $j_data = $j->job_data;
ok exists($j_data->{force});
ok exists($j_data->{cf});

