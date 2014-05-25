use strict;
use warnings;
use utf8;
use Test::More tests => 38;
use Date::Parse qw/str2time/;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";

use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo
                                   muse_file_info/;

use HTML::Entities;
use Encode;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;

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

my $testfile = catfile(t => not => parsable => 'ciao.muse');
ok (-f $testfile);
ok (!muse_file_info($testfile));
eval {
    muse_file_info("alksdjf");
};
ok ($@);

$testfile = catfile(qw/t repotest a at another-test.muse/);
ok (-f $testfile);

my $info = muse_file_info($testfile);

my $expected = {
                'f_name' => 'another-test',
                'site_id' => 'default',
                'uri' => 'another-test',
                'list_title' => 'Test',
                'parsed_categories' => [
                                        {
                                         'site_id' => 'default',
                                         'name' => "\x{e8}cole",
                                         'type' => 'topic',
                                         'uri' => 'ecole'
                                        },
                                        {
                                         'site_id' => 'default',
                                         'name' => "\x{c9}mile",
                                         'type' => 'author',
                                         'uri' => 'emile'
                                        },
                                       ],
                'f_suffix' => '.muse',
                'title' => 'Test',
                source => '',
                lang => '',
                date => '',
                attach => '',
                uid => '',
                subtitle => '',
                notes => '',
               };


foreach my $k (qw/f_timestamp f_path f_archive_rel_path f_full_path_name
                  f_timestamp_epoch/) {
    my $del = delete $info->{$k};
    ok $del, "Found $k $del";
}

my $pubdate = delete $info->{pubdate};

ok($pubdate, "Found publication date");
is(str2time($pubdate->iso8601, 'UTC'), str2time('2014-01-01 00:00', 'UTC'));

is_deeply $info, $expected, "Info returned correctly";


$testfile = catfile(qw/t repotest a at another-test-1.muse/);
$info = muse_file_info($testfile);

# is $info->{DELETED}, no
is $info->{title}, 'blabla', "title picked from list_title";
is $info->{DELETED}, 'Missing title';
ok $info->{uri};
ok $info->{pubdate}->iso8601, "found timestamp: " . $info->{pubdate}->iso8601;
# print Dumper($info);

$testfile = catfile(qw/t repotest a at another-test-2.muse/);
$info = muse_file_info($testfile);

is $info->{DELETED}, 'Missing title';
ok $info->{uri}, "Uri found";
is $info->{title}, $info->{uri}, "title set to uri";

# print Dumper ($info);

$testfile = catfile(qw/t repotest a at another-test-3.muse/);
$info = muse_file_info($testfile);

ok !$info->{parsed_categories}, "SORTauthor (missing s) is ignored";
is $info->{DELETED}, 'ignore';
ok $info->{uri}, "Uri found";

$testfile = catfile(qw/t repotest a at another-test-4.muse/);
$info = muse_file_info($testfile);
is $info->{uid}, 'bau', "Found the unique id";
is_deeply $info->{parsed_categories}, [
                                       {
                                        site_id => 'default',
                                        name => 'baux',
                                        type => 'category',
                                        uri  => 'baux',
                                       },
                                       {
                                        site_id => 'default',
                                        name => 'fido',
                                        type => 'category',
                                        uri  => 'fido',
                                       },
                                       {
                                        site_id => 'default',
                                        name => 'bobi',
                                        type => 'category',
                                        uri  => 'bobi',
                                       },
                                      ], "Found fixed categories";

