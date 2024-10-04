#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use strict;
use warnings;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use DateTime;
use Unicode::Collate::Locale;
use Test::More tests => 4;
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0collate0');

$site->update({ canonical => 'test.org', locale => 'hr' });

{
    $site->titles->delete;
    $site->categories->delete;
    my @records;
    # 1024..1278
    foreach my $char (65..90, 256..383) {
        foreach my $suffix (1..200) {
            push @records, {
                            name => "name $char $suffix",
                            list => chr($char) . " " . $suffix,
                           };
        }
    }

    my $collator = Unicode::Collate::Locale->new(locale => 'hr');

    my $now = DateTime->now;
    diag "Inserting " . scalar(@records) . " records\n";
    my $guard = $schema->txn_scope_guard;

    my $order  = 0;
    foreach my $record (reverse @records) {
        my $uri = $record->{name};
        $uri =~ s/ /-/g;
        my $title = $site->titles->create({
                                           title => $record->{name},
                                           uri => $uri,
                                           pubdate => $now,
                                           list_title => $record->{list},
                                           f_path => $uri,
                                           f_name => $uri,
                                           f_archive_rel_path => 'f/ft',
                                           f_timestamp => 0,
                                           f_full_path_name => $uri,
                                           f_suffix => "muse",
                                           f_class => 'text',
                                           sorting_pos => $order++,
                                           status => 'published',
                                           text_size => 1000,
                                           text_qualification => 'book',
                                           text_structure => '',
                                          });
        my $cat = $site->categories->create({
                                             name => $record->{list},
                                             uri => $uri,
                                             type => 'author',
                                             sorting_pos => $order++,
                                            });
        $title->add_to_categories($cat);
    }
    $guard->commit;
}

$site->categories->update({ sorting_pos => 0 });
$site->titles->update({ sorting_pos => 0 });

is ($site->categories->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-383-200');
is ($site->titles->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-383-200');
my $time = time();

my $total = $site->collation_index;

diag "Total $total changes";

is ($site->categories->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-65-1');
is ($site->titles->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-65-1');

# foreach my $title ($site->titles->search(undef, { order_by => 'sorting_pos' })->all) {
#     diag $title->list_title;
# }

diag "Sorting done in " . (time() - $time) . " seconds";

# this is taking too much for a test
# $site->generate_static_indexes(sub { diag @_ });
# {
#     my $job = $site->jobs->dequeue;
#     diag "Logging to " . $job->log_file;
#     $job->dispatch_job;
#     diag $job->logs;
# }
# # $site->delete;


