#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 12;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Utils::Jobber;

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
is $site->custom_formats->active_only->count, 0;
is $site->custom_formats->with_alias->count, 4;

foreach my $wslide ('yes', 'no') {
    foreach my $type (qw/text special/) {
        my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                    title => 'pallino-' . $wslide,
                                                lang => 'en',
                                              }, $type);
        die $err if $err;
        my $body = <<"MUSE";
#lang en
#author pinco
#title Pallino's slides? $wslide
#slides $wslide

** First chap

 - one
 - two
 - three

** Second chap

 - one
 - two
 - three


** Third chap

 - one
 - two
 - three

MUSE
        $rev->edit($body);
        $rev->commit_version;
        $rev->publish_text;
    }
}


my $jobber = AmuseWikiFarm::Utils::Jobber->new(schema => $schema,
                                               polling_interval => 0,
                                              );
for (1..20) {
    $jobber->main_loop;
}

$site->update({
               pdf => 1,
               a4_pdf => 1,
               sl_pdf => 1,
               lt_pdf => 1,
              });

$site->check_and_update_custom_formats;
is $site->custom_formats->active_only->count, 4;
is $site->custom_formats->with_alias->count, 4;

$site->rebuild_formats;

for (1..20) {
    $jobber->main_loop;
}

# check the other way around
$site->custom_formats->update({ active => 0 });
foreach my $cf ($site->custom_formats) {
    $cf->sync_site_format;
}
$site->discard_changes;
ok !$site->pdf;
ok !$site->lt_pdf;
ok !$site->sl_pdf;
ok !$site->a4_pdf;

$site->custom_formats->update({ active => 1 });
foreach my $cf ($site->custom_formats) {
    $cf->sync_site_format;
}
$site->discard_changes;
ok $site->pdf;
ok $site->lt_pdf;
ok $site->sl_pdf;
ok $site->a4_pdf;
