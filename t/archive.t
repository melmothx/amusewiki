#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 45;
use File::Slurp;
use File::Temp;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Spec::Functions qw/catdir catfile/;
use Data::Dumper;

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive;

my $id = '0test0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $archive = AmuseWikiFarm::Archive->new(code => $id,
                                          dbic => $schema);

ok($archive);
ok $archive->site, "Site exists";
ok $archive->site_exists;
is $archive->code, $id;
ok(-d $archive->repo);
ok($archive->xapian->xapian_dir);
mkdir $archive->xapian->xapian_dir unless -d $archive->xapian->xapian_dir;
ok(-d $archive->xapian->xapian_dir);
ok($archive->dbic);
ok($archive->fields);
is_deeply $archive->fields, {
                             'source' => 1,
                             'f_timestamp' => 1,
                             'pubdate' => 1,
                             'date' => 1,
                             'site_id' => 1,
                             'f_archive_rel_path' => 1,
                             'f_path' => 1,
                             'author' => 1,
                             'list_title' => 1,
                             'f_suffix' => 1,
                             'attach' => 1,
                             'id' => 1,
                             'f_full_path_name' => 1,
                             'lang' => 1,
                             'uid' => 1,
                             'f_name' => 1,
                             'deleted' => 1,
                             'uri' => 1,
                             'subtitle' => 1,
                             'notes' => 1,
                             'title' => 1,
                             'sorting_pos' => 1,
                            }, "the archive knows the title fields";


ok(!$archive->index_file);

# delete and reinsert
my $title = $schema->resultset('Title')->search({uri => 'do-this-by-yourself',
                                                 site_id => $id })->delete;

$title = $schema->resultset('Title')->single({uri => 'do-this-by-yourself',
                                              site_id => $id });

ok(!$title, "Title purged");

ok $archive->index_file(catfile(repo => $id => d => dt =>'do-this-by-yourself.muse'));

$title = $schema->resultset('Title')->single({uri => 'do-this-by-yourself',
                                              site_id => $id });
ok($title, "Title reinserted");


my $dummy_file = catfile(repo => $id => d => dt => 'dummy-text.muse');
my $dummy_content =<<'MUSE';
#title Dummy text
#author Supermarco

bla bla
MUSE

diag "Creating $dummy_file";
write_file($dummy_file, $dummy_content);
$archive->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

ok($title);
ok(!$title->deleted, "Is not deleted") or diag $title->deleted;
ok(!$title->is_deferred, "Is not deferred");
ok(!$title->is_deleted, "Is not deleted");
ok($title->is_published, "It's published");



my @cats = $title->categories;

ok(@cats == 1);
is($cats[0]->name, 'Supermarco');
is($cats[0]->uri, 'supermarco');
is($cats[0]->type, 'author');
is($cats[0]->text_count, 1);

my $dummy_content_updated =<<'MUSE';
#title Dummy text
#author Superpippo

bla bla
MUSE

write_file($dummy_file, $dummy_content_updated);
$archive->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

ok($title);

@cats = $title->categories;

ok(@cats == 1);
is($cats[0]->name, 'Superpippo');
is($cats[0]->uri, 'superpippo');
is($cats[0]->type, 'author');
is($cats[0]->text_count, 1);

# check the old author
my $deleted_cat = $schema->resultset('Category')->single({uri => 'supermarco',
                                                          type => 'author',
                                                          site_id => $id });

ok($deleted_cat);
is($deleted_cat->text_count, 0);

my $dummy_content_deferred =<<'MUSE';
#title Dummy text
#author Superpippo
#pubdate 2024-01-01

bla bla

MUSE

write_file($dummy_file, $dummy_content_deferred);
$archive->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

ok($title);
@cats = $title->categories;
ok(@cats == 0);
ok($title->is_deferred);
ok(!$title->is_published);
ok(!$title->is_deleted);


foreach my $deletion (qw/superpippo supermarco/) {
    $deleted_cat = $schema->resultset('Category')->single({uri => $deletion,
                                                           type => 'author',
                                                           site_id => $id });
    ok($deleted_cat);
    is($deleted_cat->text_count, 0);
}



my $dummy_content_deleted =<<'MUSE';
#title Dummy text
#author Superpippo
#DELETED nuked

bla bla
MUSE

write_file($dummy_file, $dummy_content_deleted);
$archive->index_file($dummy_file);

foreach my $deletion (qw/superpippo supermarco/) {
    $deleted_cat = $schema->resultset('Category')->single({uri => $deletion,
                                                           type => 'author',
                                                           site_id => $id });
    ok($deleted_cat);
    is($deleted_cat->text_count, 0);
}

unlink $dummy_file or die $!;


