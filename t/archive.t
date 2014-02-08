#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 11;
use File::Slurp;
use File::Temp;
use File::Copy qw/copy/;
use File::Path qw/make_path/;
use File::Spec::Functions qw/catdir catfile/;
use Data::Dumper;

use AmuseWikiFarm::Model::DB;
use AmuseWikiFarm::Archive;

my $id = 'test';
my $schema = AmuseWikiFarm::Model::DB->new;
my $archive = AmuseWikiFarm::Archive->new(repo => catdir(repo => $id),
                                          dbic => $schema,
                                          code => $id,
                                          xapian => catdir(xapian => $id));

ok($archive);
is $archive->code, $id;
ok(-d $archive->repo);
mkdir $archive->xapian unless -d $archive->xapian;
ok(-d $archive->xapian);
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
                             'title' => 1
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

ok($archive->xapian_db);



