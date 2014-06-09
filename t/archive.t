#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 51;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Slurp;
use File::Temp;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Spec::Functions qw/catdir catfile/;
use Data::Dumper;

use AmuseWikiFarm::Schema;

my $id = '0test0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find($id);
ok($site);
is $site->id, $id;
ok(-d $site->repo_root);
my $xapian_dir = $site->xapian->xapian_dir;
ok $xapian_dir, "found " . $xapian_dir;
mkdir $xapian_dir unless -d $xapian_dir;
ok(-d $xapian_dir);
ok($site->title_fields);
is_deeply $site->title_fields, {
                             'source' => 1,
                             'f_timestamp' => 1,
                             'f_timestamp_epoch' => 1,
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
                             'status' => 1,
                             'f_class' => 1,
                            }, "the archive knows the title fields";

ok(!$site->index_file);

# delete and reinsert
my $title = $schema->resultset('Title')->search({uri => 'do-this-by-yourself',
                                                 site_id => $id })->delete;

$title = $schema->resultset('Title')->single({uri => 'do-this-by-yourself',
                                              site_id => $id });

ok(!$title, "Title purged");

ok $site->index_file(catfile(repo => $id => d => dt =>'do-this-by-yourself.muse'));

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
$site->compile_and_index_files([$dummy_file]);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              f_class => 'text',
                                              site_id => $id });

ok($title);
ok(!$title->deleted, "Is not deleted") or diag $title->deleted;
ok($title->is_published, "It's published");
ok($title->can_spawn_revision, "can create a revision");
is($title->status, 'published');
diag $title->f_full_path_name;


my @cats = $title->categories;

ok(@cats == 1);
is($cats[0]->name, 'Supermarco');
is($cats[0]->uri, 'supermarco');
is($cats[0]->type, 'author');
is($cats[0]->text_count, 1, "supermarco has 1 text");

my $dummy_content_updated =<<'MUSE';
#title Dummy text
#author Superpippo

bla bla
MUSE

write_file($dummy_file, $dummy_content_updated);
$site->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

ok($title);

@cats = $title->categories;

ok(@cats == 1);
is($cats[0]->name, 'Superpippo');
is($cats[0]->uri, 'superpippo');
is($cats[0]->type, 'author');
is($cats[0]->text_count, 1);
is($title->status, 'published');

is $schema->resultset('Title')->latest(3)->first->uri, 'dummy-text';
is $schema->resultset('Title')->latest(1)->first->uri, 'dummy-text';

my @latest = $schema->resultset('Title')->latest(2);
ok(@latest == 2);

diag $latest[0]->pubdate;
diag $latest[1]->pubdate;
my $next_latest = $latest[1]->uri;

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
$site->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

ok($title);
@cats = $title->categories;
ok(@cats == 0);
ok(!$title->is_published);
ok($title->can_spawn_revision, "can create a revision");
ok(!$title->deleted);
is($title->status, 'deferred');

foreach my $deletion (qw/superpippo supermarco/) {
    $deleted_cat = $schema->resultset('Category')->single({uri => $deletion,
                                                           type => 'author',
                                                           site_id => $id });
    ok($deleted_cat);
    is($deleted_cat->text_count, 0);
}

diag "Now that it was deferred, the latest is $next_latest which was second";
is $schema->resultset('Title')->latest(3)->first->uri, $next_latest;

my $dummy_content_deleted =<<'MUSE';
#title Dummy text
#author Superpippo
#DELETED nuked

bla bla
MUSE

write_file($dummy_file, $dummy_content_deleted);
$site->index_file($dummy_file);

$title = $schema->resultset('Title')->single({uri => 'dummy-text',
                                              site_id => $id });

foreach my $deletion (qw/superpippo supermarco/) {
    $deleted_cat = $schema->resultset('Category')->single({uri => $deletion,
                                                           type => 'author',
                                                           site_id => $id });
    ok($deleted_cat);
    is($deleted_cat->text_count, 0);
}

is($title->status, 'deleted');
unlink $dummy_file or die $!;
$title->delete;

eval { $site->compile_and_index_files(['/etc/passwd']) };
my $exception = $@;

ok $exception, "Found $exception";

eval { $site->compile_and_index_files([File::Spec->abs2rel('/etc/passwd',
                                                          $site->repo_root)]) };
my $exception = $@;
ok $exception, "Found $exception";


