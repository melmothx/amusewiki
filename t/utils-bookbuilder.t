use strict;
use warnings;
use utf8;
use Test::More tests => 35;
use Data::Dumper;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid muse_naming_algo/;
use AmuseWikiFarm::Utils::BookBuilder;

my $bb = AmuseWikiFarm::Utils::BookBuilder->new;

my @list = (qw/a-a
               a-b-c
               bla-bla-bla
               ciao-cioa
              /);

push @list, 'a' x 95;

foreach my $valid (@list) {
    ok($bb->filename_is_valid($valid), "Valid: $valid");
    is($valid, muse_naming_algo($valid), "Double check: $valid");
}

$bb->textlist([ @list ]);

is_deeply $bb->textlist, [ @list ], "All texts are good";
ok !$bb->error;


@list = (qw/-a-a-a-
            blabla|bla
            aa
            /);

push @list, 'klasd laskdf alsdkfj';
push @list, 'a' x 96;

push @list, 'àààà';
push @list, 'l2()';
push @list, '1234-';
push @list, '/etc/passwd';
push @list, '1234,1234';
push @list, '1l239z .-asdf asdf';

foreach my $invalid (@list) {
    ok(!$bb->filename_is_valid($invalid), "Not valid: $invalid");
}

$bb->textlist([ @list ]);
is_deeply $bb->textlist, [], "All the text are removed";
ok $bb->error, "Got an error: " . $bb->error;

$bb->textlist([qw/my-good-text/]);
ok !$bb->error, "No error found with sane list";

eval {
    $bb->textlist(undef);
};

ok $@, "Putting undef in textlist raises an exception";

$bb->add_text('ciao');
is_deeply $bb->textlist, [qw/my-good-text ciao/], "Text added correctly";

$bb->delete_text(1);
is_deeply $bb->textlist, [qw/ciao/], "Text removed correctly";

$bb->move_down(1);
is_deeply $bb->textlist, [qw/ciao/], "Nothing happens";

$bb->move_up(1);
is_deeply $bb->textlist, [qw/ciao/], "Nothing happens";

$bb->add_text('appended');
is_deeply $bb->textlist, [qw/ciao appended/], "Text added";

$bb->move_down(1);
is_deeply $bb->textlist, [qw/appended ciao/], "Text swapped";

diag "Testing the moving up";
$bb->move_up(2);

is_deeply $bb->textlist, [qw/ciao appended/], "Text swapped";

$bb->delete_all;
is_deeply $bb->textlist, [], "Texts purged";
