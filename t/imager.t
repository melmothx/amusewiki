#!perl

use strict;
use warnings;
use Imager;
use Data::Dumper::Concise;
use Test::More;

ok $Imager::formats{png}, "PNG supported";
ok $Imager::formats{jpeg}, "JPEG supported";

done_testing;

1;
