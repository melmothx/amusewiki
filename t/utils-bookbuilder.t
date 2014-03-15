use strict;
use warnings;
use utf8;
use Test::More tests => 58;
use Data::Dumper;
# use Test::Memory::Cycle;


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

my $options = $bb->available_tex_options;

# $Data::Dumper::Deparse = 1;
# print Dumper($options);

is $options->{twoside}->('lkasdf'), 1;
is $options->{twoside}->(undef), 0;
is $options->{papersize}->('lasdf'), undef;
is $options->{papersize}->('a4'), 'a4';
is $options->{division}->('4'), undef;
is $options->{division}->('12'), 12;
is $options->{fontsize}->('9'), undef;
is $options->{fontsize}->('10'), 10;
is $options->{fontsize}->('10.5'), undef;
is $options->{bcor}->(''), '0mm';
is $options->{bcor}->('blabla'), '0mm';
is $options->{bcor}->('10'), '10mm';
is $options->{mainfont}->('charis'), 'Charis SIL';
is $options->{mainfont}->('libertine'), 'Linux Libertine O';
is $options->{mainfont}->('\hello'), undef;

my %params = (
              twoside => '\hello',
              garbage => 'lkjasdfl',
              schifo  => '\\\\\\\\bla',
              papersize => 'A4',
              fontsize => 10,
              bcor => 20,
              mainfont => 'cmu',
              division => '8',
              schema => '2up',
              imposed => 1,
              cover => '',
              signatures => 1,
             );

my %copy = %params;

my $validated = $bb->validate_options(\%params);

is_deeply(\%params, \%copy);

is_deeply $validated, {
                       twoside => 1,
                       papersize => 'a4',
                       division => undef,
                       fontsize => 10,
                       bcor => '20mm',
                       mainfont => 'CMU Serif',
                      }, "Validation works";



my $c_validated = $bb->validate_imposer_options(\%params);

is_deeply($c_validated, {
                         schema => '2up',
                         signature => '40-80',
                        }, "Got the options");

$params{schema} = 'blablabla';

is_deeply($c_validated, {
                         schema => '2up',
                         signature => '40-80',
                        }, "Got the options");

is $bb->validate_imposer_options(\%params), undef;
$params{schema} = '2down';

is_deeply($bb->validate_imposer_options(\%params), {
                                                    schema => '2down',
                                                    signature => '40-80',
                                                   }, "Got the options");

$params{imposed} = 0;
is $bb->validate_imposer_options(\%params), undef;

$params{imposed} = 1;
$params{signatures} = 0;

is_deeply $bb->validate_imposer_options(\%params), { schema => '2down' };


# memory_cycle_ok($bb);
