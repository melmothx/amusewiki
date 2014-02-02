use strict;
use warnings;
use utf8;
use Test::More tests => 14;

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;
use HTML::Entities;
use Encode;

my $string = "à&amp;è";
my $utf8 = encode("utf-8", $string);
is(decode_entities($string), "à&è", "encode entities is behaving correctly");
is(decode_entities($utf8), encode("utf-8", "à&è"));

is(muse_naming_algo("CrimethInc. Политика для тех, кому слишком скучно"),
   "crimethinc-politika-dlya-teh-komu-slishkom-skuchno",
   "checking naming algo 1, with cyrillic");


is(muse_naming_algo("Боб Блэк Анархия: Вопросы и Ответы"),
   "bob-blek-anarhiya-voprosy-i-otvety",
   "checking naming algo 2, with cyrillic");

is(muse_naming_algo(" Ò Purzel, my òààà\n\n\n"),
   "o-purzel-my-oaaa");

is(muse_naming_algo("g.c."), "g-c",
   "Testing not printable");

is(muse_naming_algo("äÄÅåöÖøõØÕäÄÅåöÖøõØÕ"),
   'aaaaooooooaaaaoooooo',
   "Testing new chars");

is(muse_naming_algo("čćžšđČĆŽŠĐ âÂāĀêÊîÎôÔûÛ"),
   'cczsdjcczsdj-aaaaeeiioouu',
   'Testing hr-sr chars');
   
is(muse_naming_algo("ĘęŁłŃńŚśŹźŻż ĘęŁłŃńŚśŹźŻż "),
   "eellnnsszzzz-eellnnsszzzz",
   "testing polish chars");

is(muse_naming_algo("ѓЃèÈѕЅѝЍjJљЉњЊќЌџЏјЈѐЀ"),
   "djdjeedzdziijjljljnjnjkjkjdzhdzhjjee",
   "testing macedonian cyril");

is muse_naming_algo("-ciao-"), "ciao", "testing hyphens";
is muse_naming_algo(",ciao,"), "ciao", "testing commas";
is muse_naming_algo(".ciao."), "ciao", "testing dots";
is muse_naming_algo('\\".-,ci\ao-,.'), "ci-ao", "testing weird chars";
