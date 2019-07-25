#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 154;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/read_file write_file/;
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
                             'sku' => 1,
                             'status' => 1,
                             'f_class' => 1,
                                slides => 1,
                                text_structure => 1,
                                cover => 1,
                                teaser => 1,
                                text_qualification => 1,
                                text_size => 1,
                                attachment_index => 1,
                                blob_container => 1,
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


my @cats = $title->categories->with_texts;

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

@cats = $title->categories->with_texts;

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
ok(!$schema->resultset('Category')->with_texts->single({'me.uri' => 'supermarco',
                                                        'me.type' => 'author',
                                                        'me.site_id' => $id }));


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
@cats = $title->categories->with_texts;
ok(@cats == 0);
ok(!$title->is_published);
ok($title->can_spawn_revision, "can create a revision");
ok(!$title->deleted);
is($title->status, 'deferred');

my $global_deferred_titles = $schema->resultset('Title')
  ->deferred_to_publish(DateTime->new(year => 2025,
                                      month => 1,
                                      day => 1));
ok ($global_deferred_titles->count, "Found deferred titles");
my $deferred_found = $global_deferred_titles->find({ site_id => $id,
                                                     uri => 'dummy-text',
                                                   });
ok ($deferred_found, "found deferred title to publish: " . $deferred_found->title);

foreach my $deletion (qw/superpippo supermarco/) {
    $deleted_cat = $schema->resultset('Category')->single({uri => $deletion,
                                                           type => 'author',
                                                           site_id => $id });
    ok($deleted_cat);
    ok(!$schema->resultset('Category')->active_only->single({'me.uri' => $deletion,
                                                             'me.type' => 'author',
                                                             'me.site_id' => $id }));
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
    ok(!$schema->resultset('Category')->with_texts->single({'me.uri' => $deletion,
                                                            'me.type' => 'author',
                                                            'me.site_id' => $id }));
}

is($title->status, 'deleted');
unlink $dummy_file or die $!;
$title->delete;

eval { $site->compile_and_index_files(['/etc/passwd']) };
my $exception = $@;

like $exception, qr/valid path/, "Found $exception";

eval { $site->compile_and_index_files([File::Spec->abs2rel('/etc/passwd',
                                                          $site->repo_root)]) };
$exception = $@;
like $exception, qr/valid path/, "Found $exception";


my $other = $schema->resultset('Title')
  ->search({ site_id => { '!=' => $site->id },
             status => 'published',
             f_full_path_name => { '!=' => '' }})->first->f_full_path_name;

ok (-f $other, "$other exists");

eval { $site->compile_and_index_files([File::Spec->abs2rel($other,
                                                          $site->repo_root)]) };
$exception = $@;
like $exception, qr/valid path/, "Found $exception";

eval { $site->compile_and_index_files([$other]) };
$exception = $@;
like $exception, qr/valid path/, "Found $exception";

#  - =#SORTauthors= 
#
#  If not provided, this default to =#author=. It’s a list
#  separated by semicolons or commas with the various authors. While
#  =#author= affects the display only, this one is used to index the
#  document.

my @tests = (
             {
              indexed_first_author => 'Pallino',
              author_count => 1,
              muse => "#author Anon\n#sortauthors Pallino\n#title Blabla\n\nBlabla\n",
              test_name => "sortauthors present",
              display_author => 'Anon',
             },
             {
              indexed_first_author => 'Pallino',
              author_count => 1,
              test_name => "authors and author present",
              muse => "#author Anon\n#authors Pallino\n#title Blabla\n\nBlabla\n",
              display_author => 'Anon',
             },
             {
              author_count => 1,
              muse => "#author Anon\n#title Blabla\n\nBlabla\n",
              indexed_first_author => 'Anon',
              test_name => "author is anon, no sortauthors found",
              display_author => 'Anon',
             },
             {
              author_count => 0,
              muse => "#author Anonx\n#authors -\n#title Blabla\n\nBlabla\n",
              display_author => 'Anonx',
             },
             {
              indexed_first_author => 'Pallino',
              author_count => 1,
              test_name => "authors and author",
              muse => "#author Anon\n#authors Pallino\n#title Blabla\n\nBlabla\n",
              display_author => 'Anon',
             },
             {
              author_count => 0,
              test_name => "display pippo, but no real authors",
              muse => "#title Blabla\n#sortauthors\n#author pippo\n\nBlabla\n",
              display_author => 'pippo',
             },
             {
              author_count => 0,
              test_name => "display pippo, authors with dash",
              muse => "#title Blabla\n#SORTauthors -\n#author pippo\n\nBlabla\n",
              display_author => 'pippo',
             },
             {
              author_count => 0,
              test_name => "removed authors",
              muse => "#title Blabla#slides NO\n\nBlabla\n",
              display_author => '',
             },
             {
              author_count => 0,
              test_name => "display pippo, but no real authors",
              muse => "#title Blabla\n#authors -\n#author pippo\n#slides yes\n\nBlabla\n",
              display_author => 'pippo',
              slides => 1,
             },
            );
# here there are two bugs. The first is that authors should take
# preference over 

for (1..2) {
    foreach my $test (@tests) {
        diag $test->{test_name};
        write_file($dummy_file, $test->{muse});
        my $text_obj = $site->index_file($dummy_file);
        ok ($text_obj->isa('AmuseWikiFarm::Schema::Result::Title'), "index_file returned the object");
        $title = $schema->resultset('Title')->find({ uri => 'dummy-text',
                                                     site_id => $id });
        ok ($title, "title found");
        if ($test->{author_count}) {
            is $title->authors->first->name, $test->{indexed_first_author},
              "Author is $test->{indexed_first_author}";
        }
        foreach my $author ($title->authors->all) {
            diag "Author is " . $author->name;
        }
        is ($title->authors->count, $test->{author_count}, $test->{test_name});
        is ($title->author, $test->{display_author}, "Author display is ok");
        if ($test->{slides}) {
            ok ($title->slides, "Slides required");
        }
        else {
            ok (!$title->slides, "No slides required");
        }

    }
}


unlink $dummy_file or die $!;
