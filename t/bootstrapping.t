#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
use File::Copy qw/move/;
use File::Spec::Functions qw/catfile/;
use File::Slurp;
use AmuseWikiFarm::Schema;

use Test::More tests => 5;

my $id = '0test0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find($id);

$site->update_db_from_tree;
my $files = $site->repo_find_files;

my @found = sort keys %$files;

is_deeply \@found, [
                    catfile(qw/d dt deleted-text.muse/),
                    catfile(qw/d dt do-this-by-yourself.muse/),
                    catfile(qw/f ft f-t-bad-2.muse/),
                    catfile(qw/f ft f-t-bad.muse/),
                    catfile(qw/f ft first-test.muse/),
                    catfile(qw/s st second-test.muse/),
                    catfile(qw/specials index.muse/),
                   ], "Found all the muse files, excluding images in wrong place";

my $changes = $site->repo_find_changed_files;

is_deeply $changes, {
                     new => [],
                     changed => [],
                     removed => [],
                    }, "No change found!" or diag Dumper($changes);

diag "Running it again after moving a file";

diag "Remove a file an see if it's detected";

my $target_rel_file = catfile(qw/d dt deleted-text.muse/);
my $target_abs_file = catfile($site->repo_root, qw/d dt deleted-text.muse/);

my $save = read_file($target_abs_file, { binmode => ':encoding(utf-8)' });

unlink $target_abs_file;

$changes = $site->repo_find_changed_files;
is_deeply $changes, {
                     new => [],
                     changed => [],
                     removed => [ $target_rel_file ],
                    }, "Found the removed file $target_rel_file!"
  or diag Dumper($changes);


write_file($target_abs_file, { binmode => ':encoding(utf-8)' }, $save);

$changes = $site->repo_find_changed_files;
is_deeply $changes, {
                     new => [],
                     changed => [ $target_rel_file ],
                     removed => [],
                    }, "Found the changed file $target_rel_file!"
  or diag Dumper($changes);


write_file(catfile($site->repo_root, qw/d dt d-t-test.muse/), "lassdklfa laksdf");

$changes = $site->repo_find_changed_files;
is_deeply $changes, {
                     new => [ catfile(qw/d dt d-t-test.muse/) ],
                     changed => [ $target_rel_file ],
                     removed => [],
                    }, "Found the new file!" or diag Dumper($changes);

unlink catfile($site->repo_root, qw/d dt d-t-test.muse/) or die $!;
