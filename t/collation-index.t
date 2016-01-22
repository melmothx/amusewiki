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
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->update_or_create({id => '0collate0',
                                                         canonical => 'test.org',
                                                         locale => 'hr',
                                                        });
$site->discard_changes;
$site->titles->delete;
$site->categories->delete;

# create a big db.

my @records;
# 1024..1278
foreach my $char (65..90, 256..383) {
    foreach my $suffix (1..2) {
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
foreach my $record (reverse @records) {
    my $uri = $record->{name};
    $uri =~ s/ /-/g;
    $site->titles->create({
                           title => $record->{name},
                           uri => $uri,
                           pubdate => $now,
                           list_title => $record->{list},
                           f_path => $uri,
                           f_name => $uri,
                           f_archive_rel_path => $uri,
                           f_timestamp => 0,
                           f_full_path_name => $uri,
                           f_suffix => "muse",
                           f_class => 'title',
                          });
    $site->categories->create({
                               name => $record->{list},
                               uri => $uri,
                               type => 'author',
                              });
}
$guard->commit;

is ($site->categories->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-383-2');
is ($site->titles->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-383-2');
my $time = time();

$site->collation_index;

is ($site->categories->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-65-1');
is ($site->titles->search(undef, { order_by => 'sorting_pos' })->first->uri, 'name-65-1');

# foreach my $title ($site->titles->search(undef, { order_by => 'sorting_pos' })->all) {
#     diag $title->list_title;
# }

diag "Sorting done in " . (time() - $time) . " seconds";

$site->delete;

