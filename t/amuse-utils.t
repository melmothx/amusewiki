use strict;
use warnings;
use utf8;
use Test::More tests => 43;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;

use AmuseWikiFarm::Utils::Amuse qw/muse_get_full_path
                                   muse_parse_file_path
                                   muse_filepath_is_valid
                                   muse_attachment_basename_for
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

