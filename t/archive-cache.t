#!perl

use utf8;
use strict;
use warnings;

# let's use the blog's data

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};

use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Cache;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 21;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use Data::Dumper;
use Unicode::Collate::Locale;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $cache = AmuseWikiFarm::Archive::Cache->new;

ok($cache->cache_dir, "Found the cache dir") and diag $cache->cache_dir;

$cache->clear_all;

foreach my $path ('/library', '/topics', '/authors') {
    $mech->get_ok($path);
    my $content = $mech->content;
    $mech->get_ok($path);
    is $mech->content, $content;
}

my $rs = $site->titles->published_specials;


my $collator = Unicode::Collate::Locale->new(locale => 'de', level => 1);

ok (!$collator->cmp('A', 'ä'), "German amlauts are the same") or diag $collator->cmp('A', 'Ä');

ok (!$collator->cmp('ž', 'Z'), "and Ž, Z for german are the same") or diag $collator->cmp('Ž', 'Z');

ok (!$collator->cmp('ć', 'C'), "and Ć and C for german are the same") or diag $collator->cmp('Ć', 'C');

$collator = Unicode::Collate::Locale->new(locale => 'it', level => 1);

ok (!$collator->cmp('E', 'é'), "and E, È for italian are the same") or diag $collator->cmp('E', 'È');

ok (!$collator->cmp('Ž', 'z'), "and Ž, Z for italian are the same") or diag $collator->cmp('Ž', 'Z');

ok (!$collator->cmp('ć', 'C'), "and Ć and C for italian are the same") or diag $collator->cmp('Ć', 'C');

$collator = Unicode::Collate::Locale->new(locale => 'hr', level => 1);

ok (!$collator->cmp('E', 'É'), "and E, È for croatian are the same") or diag $collator->cmp('E', 'È');

ok ($collator->cmp('Ć', 'C'), "and Ć and C for croatian are not the same") or diag $collator->cmp('Ć', 'C');

ok (!$collator->eq('Ž', 'Z'), "and Ć and C for croatian are not the same") or diag $collator->cmp('Ž', 'Z');


$cache = AmuseWikiFarm::Archive::Cache->new(lang => 'en');

my $returned = $cache->_create_library_cache_with_breakpoints(create_list('en'));

is_deeply($returned->{pager},
          [
           {
            'anchor_name' => 'A',
            'anchor_id' => 1
           },
           {
            'anchor_id' => 2,
            'anchor_name' => 'C'
           },
           {
            'anchor_name' => 'E',
            'anchor_id' => 3
           },
           {
            'anchor_id' => 4,
            'anchor_name' => 'Z'
           }
          ]);

$cache = AmuseWikiFarm::Archive::Cache->new(lang => 'hr');

$returned = $cache->_create_library_cache_with_breakpoints(create_list('hr'));

is_deeply($returned,
          {
           'pager' => [
                        {
                          'anchor_name' => 'A',
                          'anchor_id' => 1
                        },
                        {
                          'anchor_name' => 'C',
                          'anchor_id' => 2
                        },
                        {
                          'anchor_id' => 3,
                          'anchor_name' => "\x{106}"
                        },
                        {
                          'anchor_id' => 4,
                          'anchor_name' => 'E'
                        },
                        {
                          'anchor_id' => 5,
                          'anchor_name' => 'Z'
                        },
                        {
                          'anchor_id' => 6,
                          'anchor_name' => "\x{17d}"
                        }
                      ],
           'texts' => [
                        {
                          'anchor_id' => 1,
                          'anchor_name' => 'A'
                        },
                        {
                          'full_uri' => "\x{e4}a-uri",
                          'first_char' => 'A',
                          'list_title' => "\x{e4}a list title ",
                          'author' => "\x{e4}a author",
                          'title' => "\x{e4}a title",
                          'lang' => "\x{e4}a lang"
                        },
                        {
                          'lang' => 'Ab lang',
                          'list_title' => 'Ab list title ',
                          'title' => 'Ab title',
                          'author' => 'Ab author',
                          'first_char' => 'A',
                          'full_uri' => 'Ab-uri'
                        },
                        {
                          'full_uri' => "\x{c4}ca-uri",
                          'first_char' => 'A',
                          'list_title' => "\x{c4}ca list title ",
                          'author' => "\x{c4}ca author",
                          'title' => "\x{c4}ca title",
                          'lang' => "\x{c4}ca lang"
                        },
                        {
                          'anchor_id' => 2,
                          'anchor_name' => 'C'
                        },
                        {
                          'lang' => 'Cb lang',
                          'author' => 'Cb author',
                          'list_title' => 'Cb list title ',
                          'title' => 'Cb title',
                          'first_char' => 'C',
                          'full_uri' => 'Cb-uri'
                        },
                        {
                          'anchor_id' => 3,
                          'anchor_name' => "\x{106}"
                        },
                        {
                          'list_title' => "\x{107}a list title ",
                          'author' => "\x{107}a author",
                          'title' => "\x{107}a title",
                          'lang' => "\x{107}a lang",
                          'first_char' => "\x{106}",
                          'full_uri' => "\x{107}a-uri"
                        },
                        {
                          'anchor_name' => 'E',
                          'anchor_id' => 4
                        },
                        {
                          'lang' => "\x{e8}a lang",
                          'list_title' => "\x{e8}a list title ",
                          'title' => "\x{e8}a title",
                          'author' => "\x{e8}a author",
                          'full_uri' => "\x{e8}a-uri",
                          'first_char' => 'E'
                        },
                        {
                          'title' => "\x{e9}b title",
                          'list_title' => "\x{e9}b list title ",
                          'author' => "\x{e9}b author",
                          'lang' => "\x{e9}b lang",
                          'first_char' => 'E',
                          'full_uri' => "\x{e9}b-uri"
                        },
                        {
                          'lang' => 'Ec lang',
                          'list_title' => 'Ec list title ',
                          'title' => 'Ec title',
                          'author' => 'Ec author',
                          'first_char' => 'E',
                          'full_uri' => 'Ec-uri'
                        },
                        {
                          'first_char' => 'E',
                          'full_uri' => "\x{e9}d-uri",
                          'list_title' => "\x{e9}d list title ",
                          'title' => "\x{e9}d title",
                          'author' => "\x{e9}d author",
                          'lang' => "\x{e9}d lang"
                        },
                        {
                          'anchor_id' => 5,
                          'anchor_name' => 'Z'
                        },
                        {
                          'list_title' => 'zb list title ',
                          'author' => 'zb author',
                          'title' => 'zb title',
                          'lang' => 'zb lang',
                          'full_uri' => 'zb-uri',
                          'first_char' => 'Z'
                        },
                        {
                          'anchor_id' => 6,
                          'anchor_name' => "\x{17d}"
                        },
                        {
                          'first_char' => "\x{17d}",
                          'full_uri' => "\x{17d}a-uri",
                          'title' => "\x{17d}a title",
                          'list_title' => "\x{17d}a list title ",
                          'author' => "\x{17d}a author",
                          'lang' => "\x{17d}a lang"
                        }
                      ]
          }) or diag Dumper($returned);


sub create_list {
    my ($lang) = @_;
    my @testentries = (qw/äa Ab Äca ća Cb èa éb Ec éd zb Ža/);
    my $collator = Unicode::Collate::Locale->new(locale => $lang);
    my @sorted = $collator->sort(@testentries);
    my @rs;
    foreach my $entry (@sorted) {
        my $row = {
                   author => $entry . ' author',
                   title => $entry . ' title',
                   list_title => $entry . ' list title ',
                   full_uri => $entry . '-uri',
                   lang => $entry . ' lang',
                  };
        if ($row->{list_title} =~ m/(\w)/) {
            $row->{first_char} = uc($1);
            push @rs, $row;
        }
    }
    return \@rs;
}
