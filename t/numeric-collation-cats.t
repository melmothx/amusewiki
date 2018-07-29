#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 5;
use Data::Dumper::Concise;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";



my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0collate1';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({ secure_site => 0 });


# we need only one text, with a lot of categories
my @cats = ("AAA 111, first one", "AAA 2, second one", "BBB, third one");

{
    my ($rev) = $site->create_new_text({
                                        title => "Test",
                                        textbody => '<p>ciao</p>',
                                       }, 'text');
    foreach my $prefix (qw/Journal Magazine/) {
        foreach my $index (0..33) {
            foreach my $postfix (undef, qw/Bau Miao/) {
                push @cats, $prefix . ' #' . $index . ($postfix ? (" " . $postfix) : '');
            }
        }
    }
    push @cats, "Whatever";
    $rev->edit("#SORTtopics " . join(";\n", reverse @cats) . "\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
}


my @got = $site->categories->topics_only->sorted
  ->search(undef,
           {
            result_class => 'DBIx::Class::ResultClass::HashRefInflator',
            columns => [qw/name sorting_pos/],
           });
diag Dumper(\@got);

# now, we created the categories in the expected order, so we just
# need to check them.
{
    my $i = 0;
    is_deeply(\@got, [ map { +{ sorting_pos => ++$i, name => $_ } } @cats ]);
}

is_deeply $site->categories->search({ uri => 'whatever' })->first->sorting_fragments,
  [ 'Whatever', 0, ''];
is_deeply $site->categories->search({ uri => 'magazine-33' })->first->sorting_fragments,
  [ 'Magazine #', 33, ''];
is_deeply $site->categories->search({ uri => 'magazine-33-bau' })->first->sorting_fragments,
  [ 'Magazine #', 33, 'Bau'];
