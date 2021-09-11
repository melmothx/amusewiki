use strict;
use warnings;
use utf8;
use Test::More tests => 136;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use Data::Dumper::Concise;

use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_parse_file_path
                                   muse_filepath_is_valid
                                   muse_filename_is_valid
                                   muse_naming_algo
                                   muse_attachment_basename_for
                                   clean_username
                                   amw_meta_stripper
                                   build_full_uri
                                   build_repo_path
                                  /;

is_deeply(muse_get_full_path("cacca"), [ "c", "ca", "cacca" ]);
is_deeply(muse_get_full_path("th-the-best"), [ "t", "tt", "th-the-best" ]);
is(muse_get_full_path("th the-best"),
   undef,
   "Testing bad paths");
is(muse_get_full_path("../../etc/passwd"),
   undef,
   "Testing bad paths");

is(muse_get_full_path("/etc/passwd"),
   undef,
   "Testing bad paths");
is(muse_get_full_path('%a0/passwd'),
   undef,
   "Testing bad paths");

is_deeply(muse_get_full_path("zo-d-axa-us"), ["z", "zd", "zo-d-axa-us"],
	  "Testing new algo for path");


my $file = catfile(qw/t repotest a at another-test.muse/);
ok (-f $file);
my $info = muse_parse_file_path($file, catdir(qw/t repotest/));
ok ($info);
is $info->{f_name}, 'another-test';
is $info->{f_suffix}, '.muse';

$file = catfile(qw/t files shot.jpg/);

ok (-f $file);
$info = muse_parse_file_path($file, '.');
ok !$info, "Nothing returned";

$info = muse_parse_file_path($file, '.', 1);
ok !$info, "Wrong root, still invalid";

$info = muse_parse_file_path($file, catdir(qw/t files/), 1);
ok $info, "The file $file was parsed";
is $info->{f_name}, 'shot', "Found the f_name";
is $info->{f_suffix}, '.jpg', "Found the f_suffix";
ok $info->{f_full_path_name}, "Found $info->{f_full_path_name}";
ok !$info->{f_archive_rel_path}, "No archive rel path";


my @valid = (
             [qw/uploads test.pdf/],
             [qw/a am a-muse.muse/],
             [qw/a as anonymous.muse/],
             [qw/t tt test.muse/],
             [qw/d dt do-this-by-yourself.muse/],
             [qw/f ft f-t-bad-2.muse/],
             [qw/f ft f-t-bad.muse/],
             [qw/s st second-test.muse/],
             [qw/f ft first-test.muse/],
             [qw/d dt deleted-text.muse/],
             [qw/v v1 version-1.muse/],
             [qw/w w1 wp1.muse/],
             [qw/w w1 wpi-1.muse/],
             [qw/w w1 wpi-1-1.muse/],
             [qw/w wa wa-a.muse/],
             [qw/w wa wpi-a.muse/],
             [qw/w wb wpi-b.muse/],
             [qw/w wb wpi-b-c.muse/],
            );
my @invalid = (
               [qw/a as anonymous.pdf/],
               [qw/t tt test.pdf/],
               [qw/a s anonymous.muse/],
               [qw/a am test.muse/],
               [qw/bla.pdf/],
               [qw/h he hello_ehere.muse/],
               [qw/prova/],
               [qw/hello world ciao.muse/],
               [qw/a b t tt test.muse/],
               [qw/.git ar prova.jpg/],
               [qw/w wi wpi-.muse/],
               [qw/w wb wpi-b-.muse/],
               [qw/w wb wpi-b-c-.muse/],
               [qw/w wb Wpi-B-C.muse/],
               [qw/w wb Wpi-B_C.muse/],
               [qw/w wi w_i.muse/],
               [qw/w wi wpi-b-c.muse/],
               [qw/a wb wpi-b-c.muse/],
              );

foreach my $v (@valid) {
    my $f = catfile(@$v);
    ok(muse_filepath_is_valid($f), "$f is valid");
}
foreach my $v (@invalid) {
    my $f = catfile(@$v);
    ok(!muse_filepath_is_valid($f), "$f is invalid as expected");
}

is muse_attachment_basename_for("test"), "t-t-test";
is muse_attachment_basename_for("my-uri"), "m-u-my-uri";
is muse_attachment_basename_for("my-uri-123456789-123456789-123456789-123456789-123456789"), "m-u-my-uri-123456789-123456789-123456789-123456789";

eval { muse_attachment_basename_for("_this_") };
ok $@, "Found exception $@";

my $test_uri = muse_naming_algo("abc " x 30);
is (length($test_uri), 95, "$test_uri is shorter than 96 chars");

$test_uri = muse_naming_algo('Алексей Алексеевич Боровой Анархизм Общественные идеалы современного человечества. Либерализм. Социализм.');
is (length($test_uri), 95, "$test_uri is shorter than 96 chars");
ok muse_filename_is_valid($test_uri), "$test_uri is fully valid";
$test_uri .= 'x';
ok !muse_filename_is_valid($test_uri), "$test_uri is not valid (by one)";

{
    my $pt = 'cedilha (ç), accent (á, é, í, ó, ú), accent (â, ê, ô), tilde (ã, õ), accent (à)';
    my $uc = 'CEDILHA (Ç), ACCENT (Á, É, Í, Ó, Ú), ACCENT (Â, Ê, Ô), TILDE (Ã, Õ), ACCENT (À)';
    is muse_naming_algo($pt), 'cedilha-c-accent-a-e-i-o-u-accent-a-e-o-tilde-a-o-accent-a';
    is muse_naming_algo($uc), 'cedilha-c-accent-a-e-i-o-u-accent-a-e-o-tilde-a-o-accent-a';
}

is (clean_username('marco'), "marco");
is (clean_username('pallino pinco'), "pallinopinco");
is (clean_username(), "anonymous");
is (clean_username(0), "anonymous");
is (clean_username(undef), "anonymous");
is (clean_username(""), "anonymous");
is (clean_username("&%!"), "anonymous");
is (clean_username("Алексей"), "aleksei");
is (clean_username("ljuto"), "ljuto");
is (clean_username("ljuto.anon"), "ljuto.anon");
is (clean_username("m p"), "mp");
is (clean_username("mp."), "mp");
is (clean_username("mp.a"), "mp.a");
is (clean_username(".mp.a"), "mpa");
is (clean_username("jogurt a asdf"), "jogurtaasdf");
is (clean_username(("a" x 20) . ("b" x 20)), "a" x 20,
    "username truncated at 20 chars");
is (clean_username(("a!" x 20) . ("b" x 20)), "a" x 20,
    "username truncated at 20 chars");
is (amw_meta_stripper(), '');
is (amw_meta_stripper('<em>My title</em>'), "My title");
is (amw_meta_stripper(' <em>My title</em> '), "My title");
is (amw_meta_stripper('<em>My title> >>"<'), "My title");
is (amw_meta_stripper('"<em>My title> >>"<'), "My title");
is (amw_meta_stripper('\'<em>My title> >>"<\''), "'My title '");
is (amw_meta_stripper('12345 678 ' x 16), ('12345 678 ' x 15) . '12345...');
is (amw_meta_stripper('12345 678 ' x 15), ('12345 678 ' x 14) . '12345 678');
is (amw_meta_stripper(('12345 678 ' x 15) . 'lkajsdalksdjflkakasdklf'),
    ('12345 678 ' x 14) . '12345 678...');

is AmuseWikiFarm::Utils::Amuse::get_corrected_path('test.muse'), 't/tt/test.muse';

foreach my $spec ([ {}, undef ],
                  [
                   {
                    class => 'Title',
                   }, undef, undef
                  ],
                  [
                   {
                    f_class => 'text',
                   }, undef, undef
                  ],
                  [{
                    class => 'Title',
                    f_class => 'text',
                   }, '/library', undef ],
                  [{
                    class => 'Title',
                    f_class => 'text',
                    uri => '',
                   }, '/library/', undef],

                  [{
                    class => 'Title',
                    f_class => 'text',
                    uri => 'pizza',
                   }, '/library/pizza', 'p/pa/pizza'],

                  [{
                    class => 'Title',
                    f_class => 'text',
                    uri => 'pizza.muse',
                   }, '/library/pizza.muse', 'p/pa/pizza.muse'],

                  [{
                    class => 'Title',
                    f_class => 'special',
                   }, '/special', undef],
                  [{
                    class => 'Title',
                    f_class => 'special',
                    uri => '',
                   }, '/special/', undef],

                  [{
                    class => 'Title',
                    f_class => 'special',
                    uri => 'pizza',
                   }, '/special/pizza', 'specials/pizza'],

                  [{
                    class => 'Title',
                    f_class => 'special',
                    uri => 'pizza.muse',
                   }, '/special/pizza.muse', 'specials/pizza.muse'],

                  [{
                    class => 'Titlex',
                    f_class => 'special',
                    uri => 'pizza',
                   }, undef, undef],
                  [{
                    class => 'Title',
                    f_class => 'specialxx',
                    uri => 'pizza',
                   }, undef , undef],
                  [{
                    class => 'Attachment',
                    f_class => 'asdfa',
                    uri => 'pizza',
                   }, undef, undef],
                   [{
                    class => 'Attachment',
                    f_class => 'image',
                   }, '/library', undef],

                  [{
                    class => 'Attachment',
                    f_class => 'image',
                    uri => 'pizza.jpg',
                   }, '/library/pizza.jpg', 'p/pa/pizza.jpg'
                  ],

                  [{
                    class => 'Attachment',
                    f_class => 'special_image',
                    uri => 'pizza.jpg',
                   }, '/special/pizza.jpg',
                   'specials/pizza.jpg'
                  ],

                  [{
                    class => 'Attachment',
                    f_class => 'special_image',
                    uri => 'pizza.jpg',
                    site_id => 'xx'
                   }, '/special/pizza.jpg',
                   'repo/xx/specials/pizza.jpg'
                  ],
                  [{
                    class => 'Attachment',
                    f_class => 'upload_pdf',
                    uri => 'pizza.pdf',
                   }, undef, 'uploads/pizza.pdf'],
                   [{
                    class => 'Attachment',
                    f_class => 'upload_binary',
                     uri => 'pizza.mov',
                    }, undef, 'uploads/pizza.mov'],
                  [{
                    class => 'Attachment',
                    f_class => 'upload_pdf',
                    uri => 'pizza.pdf',
                    site_id => 'blog',
                   }, '/uploads/blog/pizza.pdf',
                   'repo/blog/uploads/pizza.pdf'
                  ],
                  [{
                    class => 'Attachment',
                    f_class => 'upload_binary',
                    uri => 'pizza.mov',
                    site_id => 'blog',
                   }, '/uploads/blog/pizza.mov',
                   'repo/blog/uploads/pizza.mov'
                  ],
                 ) {
    diag Dumper($spec);
    my ($spec, $full_uri, $repo_path) = @$spec;
    my ($outcome, $outpath);
    eval { $outcome = build_full_uri($spec) };
    diag $@ if $@;
    is $outcome, $full_uri, "Expected OK";
    eval { $outpath = build_repo_path($spec) };
    diag $@ if $@;
    is $outpath, $repo_path, "Repo path OK";
}

