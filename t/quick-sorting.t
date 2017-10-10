#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use DateTime;
use Data::Dumper::Concise;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0sorting1');

ok !$site->titles->count;
ok !$site->categories->count;

my $now = DateTime->now;
{
    my $guard = $schema->txn_scope_guard;
    for my $string (reverse('a'..'z')) {
        for my $substring (reverse('a'..'z')) {
            my $title = $string . $substring;
            add_elements($title);
        }
    }
    $guard->commit;
}

{
    ok $site->titles->unsorted_records->count, "Unsorted titles found" or die;
    ok $site->categories->unsorted_records->count, "Unsorted cats found";
    my $changed = $site->collation_index;
    ok $changed, "Changed $changed records";
}
{
    # add some titles and cats.
    foreach my $name ("0002-added", "0001-added", "0000-added", "zzzz2-added", "zzzz4-added", "zzzz3-added",
                      "hhhh-added", "tttt-added", "zzzz1-added") {
        add_elements($name);
    }
    my $changed = $site->collation_index;
    is $changed, 27, "Expected 9 * 3 changed records and got $changed";
}

ok !$site->titles->unsorted_records->count, "No unsorted titles found";
ok !$site->categories->unsorted_records->count, "No unsorted cats found";

is $site->titles->sorted_records->count, $site->titles->count, "all titles are sorted";
is $site->categories->sorted_records->count, $site->categories->count, "all cats are sorted";

$site->titles->update({ sorting_pos => 0 });
$site->categories->update({ sorting_pos => 0 });
$site->old_collation_index;
$site->titles->update({ sorting_pos => 0 });
$site->categories->update({ sorting_pos => 0 });
$site->collation_index;


sub add_elements {
    my ($title) = @_;
    $site->add_to_titles({
                          title => "$title title",
                          list_title => "$title title",
                          f_class => "text",
                          pubdate => $now,
                          uri => "$title-title",
                          status => "published",
                          f_path => "dummy",
                          f_name => "$title-title.muse",
                          f_archive_rel_path => "",
                          f_timestamp => $now,
                          f_timestamp_epoch => $now->epoch,
                          f_full_path_name => '',
                          f_suffix => ".muse",
                         });
    foreach my $type (qw/author topic/) {
        $site->add_to_categories({
                                  name => "$title $type",
                                  type => $type,
                                  uri => "$title-$type",
                                 });
    }
}
