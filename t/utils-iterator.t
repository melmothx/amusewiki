#!perl

use strict;
use warnings;
use Test::More tests => 12;
use AmuseWikiFarm::Utils::Iterator;
my $iter = AmuseWikiFarm::Utils::Iterator->new([1,2,3]);
is $iter->count, 3;
foreach my $expected (1..3) {
    is $expected, $iter->next;
}
ok !$iter->next;
ok !$iter->next;

is $iter->count, 3;

$iter->reset;
foreach my $expected (1..3) {
    is $expected, $iter->next;
}
ok !$iter->next;
ok !$iter->next;
