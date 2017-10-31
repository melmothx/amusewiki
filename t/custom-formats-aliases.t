#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 214;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Utils::Jobber;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;

my $site = create_site($schema, '0cformats0');
$site->update({ secure_site => 0 });

# reset for testing purpose, created by the after modifier.
$site->custom_formats->delete;

foreach my $alias (qw/sl.pdf a4.pdf lt.pdf pdf/) {
    $site->custom_formats->create({
                                   format_name => $alias,
                                   format_alias => $alias,
                                   ($alias eq 'sl.pdf' ? (bb_format => 'slides') : (bb_format => 'pdf')),
                                  });
}
foreach my $custom (qw/epub pdf slides/) {
    $site->custom_formats->create({
                                   format_name => $custom,
                                   bb_format => $custom,
                                  });
}


foreach my $alias (qw/sl.pdf a4.pdf lt.pdf pdf/) {
    eval { $site->custom_formats->create({
                                          format_name => $alias,
                                          format_alias => $alias,
                                         });
       };
    ok $@, "Cannot duplicate the alias $alias $@";
      
}


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

# this is faster but I need to see the output
# my $jobber = AmuseWikiFarm::Utils::Jobber->new(schema => $schema);
# for (1..10) {
#     $jobber->main_loop;
# }

foreach my $j ($site->jobs->pending) {
    $j->dispatch_job;
    diag $j->logs;
    is $j->status, 'completed';
}


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $text ($site->titles) {
    foreach my $cf ($site->custom_formats) {
        $mech->get_ok($text->full_uri);
        if ($cf->is_slides and !$text->slides) {
            foreach my $ext ($cf->tex_extension, $cf->format_alias, $cf->extension) {
                if ($ext) {
                    $mech->get($text->full_uri . '.' . $ext);
                    is $mech->status, 404, "No $ext found for slides and no actual slides";
                }
            }
        }
        else {
            $mech->get_ok($text->full_uri . '.' . $cf->extension);
            $mech->get_ok($text->full_uri . '.' . $cf->tex_extension) if $cf->is_pdf;
            $mech->get_ok($text->full_uri . '.' . $cf->format_alias) if $cf->format_alias;
            if ($cf->is_slides) {
                $mech->get($text->full_uri . '.' . $cf->tex_extension);
                $mech->content_contains('\documentclass[ignorenonframetext]{beamer}');
            }
        }
    }
}

foreach my $mirror (qw/index.html authors.html topics.html/) {
    $mech->get_ok("/mirror/$mirror");
    $mech->page_links_ok("All the links are fine in /mirror/$mirror");
}

$site->update({
               division => 15,
               bcor => '9mm',
               fontsize => 12,
               mainfont => 'TeX Gyre Pagella',
               sansfont => 'TeX Gyre Heros',
               sansfont => 'TeX Gyre Cursor',
               beamertheme => 'Madrid',
               beamercolortheme => 'albatross',
               twoside => 1,
               nocoverpage => 1,
              });
foreach my $cf ($site->custom_formats) {
    $cf->sync_from_site;
    is $cf->bb_division, 15;
    is $cf->bb_bcor, 9;
    is $cf->bb_mainfont, $site->mainfont;
    is $cf->bb_sansfont, $site->sansfont;
    is $cf->bb_monofont, $site->monofont;
    is $cf->bb_beamercolortheme, $site->beamercolortheme;
    is $cf->bb_beamertheme, $site->beamertheme;
    is $cf->bb_twoside, $site->twoside;
    is $cf->bb_coverpage_only_if_toc, $site->nocoverpage;
}

$site->update({ division => 55 });
ok !$site->bb_values;
$site->update({ division => 15 });
ok scalar($site->bb_values);

foreach my $special ($site->titles->specials_only) {
    foreach my $cf ($site->custom_formats) {
        if ($cf->bb_format eq 'slides' and !$special->slides) {
            ok !$cf->remove_stale_files($special), "No removal needed";
        }
        else {
            ok $cf->remove_stale_files($special), "State files purged";
        }
    }
}
