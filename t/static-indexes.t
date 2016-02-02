#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file read_file/;

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

use AmuseWikiFarm::Archive::StaticIndexes;
use Data::Dumper;
use Test::More tests => 32;
use DateTime;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $indexes = $site->static_indexes_generator;

ok($indexes);

my @targets = (qw/titles topics authors/);

my @files;
foreach my $method (map { $_ . '_file' } @targets) {
    my $file = $indexes->$method;
    ok ($file);
    diag $file;
    if (-f $file) {
        diag "removing $file";
        unlink $file or die "Cannot remove $file $!";
    }
    push @files, $file;
}

foreach my $method (map { 'create_' . $_ } @targets) {
    ok ($indexes->$method, "$method returns something");
}

$indexes->generate;

like $indexes->css, qr/div#page \{/, "Found css rule in css method";

foreach my $file (@files) {
    ok (-f $file, "$file was generated");
    my $content = read_file($file);
    unlike $content, qr{\[\%}, "No opening TT tokens found in $file";
    unlike $content, qr{\%\]}, "No closing TT tokens found in $file";
    like $content, qr{<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="hr" lang="hr">}, "Found html tag in $file";
    like $content, qr/div#page \{/, "Found css rule in $file";
    like $content, qr/<div id="page">/, "Found container in $file";
    like $content, qr/My first test/, "Found text in $file";
    like $content, qr/first-test/, "Found text in $file";
}

# stress test

if (my $xsite = $schema->resultset('Site')->find('0stressidx0')) {
    my $time = time();
    $xsite->static_indexes_generator->generate;
    diag "Done in " . (time() - $time) . " seconds";
}
else {
    $xsite = $schema->resultset('Site')->update_or_create({id => '0stressidx0',
                                                              canonical => 'xtest.org',
                                                              locale => 'hr',
                                                             });
    $xsite->discard_changes;
    my $guard = $schema->txn_scope_guard;
    $xsite->discard_changes;
    $xsite->titles->delete;
    $xsite->categories->delete;
    my $now = DateTime->now;
    foreach my $suffix ('a'..'z') {
        diag "Adding texts for $suffix";
        foreach my $ssuffix (1 .. 2) {
            my $uri = 'title-' . $suffix . '-' . $ssuffix;
            my $text = $xsite->titles->create({
                                               title => "title $suffix $ssuffix",
                                               uri => $uri,
                                               f_path => $uri,
                                               f_name => $uri,
                                               f_archive_rel_path => $uri,
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
    my $time = time();
    $xsite->static_indexes_generator->generate;
    diag "Done in " . (time() - $time) . " seconds";
}
