#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 14;
use AmuseWikiFarm::Utils::Paginator;
use Data::Dumper;
use Data::Page;

# test with 1 and 0 items

my $pager = Data::Page->new;
$pager->total_entries(40);
$pager->entries_per_page(3);
$pager->current_page(1);

my $sub = sub {
    return '/latest/' . $_[0];
};

my $pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

my $left = '<i class="fa fa-chevron-left"></i><span class="sr-only">«<span>';
my $right = '<i class="fa fa-chevron-right"></i><span class="sr-only">»<span>';


is_deeply($pages->items, [
                   {
                    'label' => 1,
                    'active' => 1,
                    'uri' => '/latest/1'
                   },
                   {
                    'uri' => '/latest/2',
                    'label' => 2
                   },
                   {
                    'uri' => '/latest/3',
                    'label' => 3
                   },
                   {
                    label => '...',
                   },
                   {
                    'uri' => '/latest/13',
                    'label' => 13
                   },
                   {
                    'uri' => '/latest/14',
                    'label' => 14
                   },
                   {
                    'label' => $right,
                    'uri' => '/latest/2'
                   }
                  ]);

is $pages->prev_url, undef;
is $pages->next_url, '/latest/2';

$pager->current_page(8);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

is_deeply($pages->items,
          [
           {
            'label' => $left,
            'uri' => '/latest/7'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'label' => 6,
            'uri' => '/latest/6'
           },
           {
            'uri' => '/latest/7',
            'label' => 7
           },
           {
            'label' => 8,
            'active' => 1,
            'uri' => '/latest/8'
           },
           {
            'label' => 9,
            'uri' => '/latest/9'
           },
           {
            'uri' => '/latest/10',
            'label' => 10
           },
           {
            'label' => '...'
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14
           },
           {
            'uri' => '/latest/9',
            'label' => $right,
           }
          ]);





$pager->current_page(9);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);

is_deeply($pages->items,
          [
           {
            'label' => $left,
            'uri' => '/latest/8'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'label' => 7,
            'uri' => '/latest/7'
           },
           {
            'label' => 8,
            'uri' => '/latest/8'
           },
           {
            'label' => 9,
            'active' => 1,
            'uri' => '/latest/9'
           },
           {
            'uri' => '/latest/10',
            'label' => 10
           },
           {
            'label' => 11,
            'uri' => '/latest/11',
           },
           {
            'label' => '...',
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14
           },
           {
            'uri' => '/latest/10',
            'label' => $right,
           }
          ]) or diag Dumper($pages);

is $pages->next_url, '/latest/10';
is $pages->prev_url, '/latest/8';

$pager->current_page(14);

$pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);
is_deeply($pages->items,
          [
           {
            'label' => $left,
            'uri' => '/latest/13'
           },
           {
            'label' => 1,
            'uri' => '/latest/1'
           },
           {
            'uri' => '/latest/2',
            'label' => 2
           },
           {
            'label' => '...'
           },
           {
            'uri' => '/latest/12',
            'label' => 12
           },
           {
            'uri' => '/latest/13',
            'label' => 13
           },
           {
            'uri' => '/latest/14',
            'label' => 14,
            active => 1,
           },
          ]) or diag Dumper($pages);

is  $pages->prev_url, '/latest/13';
is  $pages->next_url, undef;


{
    my $pager = Data::Page->new;
    $pager->total_entries(1);
    $pager->entries_per_page(10);
    $pager->current_page(1);
    $pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);
    is $pages->next_url, undef;
    is $pages->prev_url, undef;

}

{
    my $pager = Data::Page->new;
    $pager->total_entries(0);
    $pager->entries_per_page(10);
    $pager->current_page(1);
    $pages = AmuseWikiFarm::Utils::Paginator::create_pager($pager, $sub);
    is $pages->next_url, undef;
    is $pages->prev_url, undef;
}
