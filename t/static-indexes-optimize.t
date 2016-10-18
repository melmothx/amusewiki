#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWikiFarm::Archive::StaticIndexes;
use Data::Dumper;
use DateTime;
use File::Spec::Functions qw/catfile/;
use File::Basename;
use Test::More skip_all => 'Not required';
use Test::Differences;
use Test::WWW::Mechanize::Catalyst;
my $schema = AmuseWikiFarm::Schema->connect('amuse');

# stress test

my $xsite = $schema->resultset('Site')->find('0stressidx0');

unless ($xsite) {
    $xsite = $schema->resultset('Site')->update_or_create({id => '0stressidx0',
                                                           canonical => '0stressidx0.amusewiki.org',
                                                           locale => 'hr',
                                                           secure_site => 0,
                                                          });
    $xsite->discard_changes;
    my $guard = $schema->txn_scope_guard;
    $xsite->discard_changes;
    $xsite->titles->delete;
    $xsite->categories->delete;
    my $now = DateTime->now;
    foreach my $suffix ('a'..'z') {
        diag "Adding texts for $suffix";
        foreach my $ssuffix (1 .. 30) {
            my $uri = 'title-' . $suffix . '-' . $ssuffix;
            my $text = $xsite->titles->create({
                                               title => "title $suffix $ssuffix",
                                               uri => $uri,
                                               f_path => $uri,
                                               f_name => $uri,
                                               f_archive_rel_path => "t/t$suffix",
                                               f_timestamp => 0,
                                               f_full_path_name => $uri,
                                               f_suffix => "muse",
                                               f_class => 'text',
                                               pubdate => $now,
                                               status => 'published',
                                              });
            my @categories;
            foreach my $cat ('a' .. 'z') {
                foreach my $num (1 .. 2) {
                    foreach my $type (qw/author topic/) {
                        push @categories, {
                                           name => "$type $cat $num",
                                           uri => $type . '-' . $cat . '-' . $num,
                                           type => $type,
                                           site_id => $xsite->id,
                                           text_count => 10, # bogus
                                          };
                    }
                }
            }
            $text->set_categories(\@categories);
        }
    }
    $guard->commit;
    diag "Done with the spam-insertion";
}
diag "Sorting the stuff";
$xsite->collation_index;
diag "generating static indexes";
my $time = time();
my $generator = $xsite->static_indexes_generator;
$generator->generate;
diag "Done in " . (time() - $time) . " seconds";
foreach my $file (qw/titles.html authors.html  topics.html/) {
    my $got = read_file(catfile(qw/repo 0stressidx0/, $file));
    my $exp = read_file(catfile(qw/t static-indexes-expected/, $file));
    eq_or_diff $got, $exp, $file;
}
{
    $xsite->update({ mode => 'modwiki' });
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $xsite->canonical);

    # used to be 30+ seconds
    diag "Requesting /opds/crawlable";
    $time = time();
    $mech->get_ok('/opds/crawlable');
    # diag $mech->content;
    diag "Request in " . (time() - $time) . " seconds";
}
