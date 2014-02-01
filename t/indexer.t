use strict;
use warnings;
use utf8;
use Test::More;

use AmuseWikiFarm::Utils::Amuse;
use HTML::Entities;
use Encode;

my $string = "à&amp;è";
my $utf8 = encode("utf-8", $string);
is(decode_entities($string), "à&è", "encode entities is behaving correctly");
is(decode_entities($utf8), encode("utf-8", "à&è"));
done_testing;

