use strict;
use warnings;
use utf8;
use Test::More tests => 69;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
# use Test::Memory::Cycle;
use JSON qw/to_json from_json/;
use Try::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid muse_naming_algo/;
use AmuseWikiFarm::Archive::BookBuilder;

my $bb = AmuseWikiFarm::Archive::BookBuilder->new;

my @list = (qw/a-a
               a-b-c
               bla-bla-bla
               ciao-cioa
              /);

push @list, 'a' x 95;

foreach my $valid (@list) {
    ok($bb->add_text($valid), "Valid: $valid");
    is($valid, muse_naming_algo($valid), "Double check: $valid");
}

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
    ok(!$bb->add_text($invalid), "Not valid: $invalid");
    ok($invalid ne muse_naming_algo($invalid), "Double check invalid: $invalid");
}

eval {
    $bb->textlist(undef);
};

ok $@, "Putting undef in textlist raises an exception: " . $@->message;

$bb->delete_all;
ok($bb->add_text('my-good-text'));
ok($bb->add_text('ciao'));
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


my @accessors = (
                 [ twoside => 'lkasdf', 0],
                 [ twoside => undef, undef],
                 [ papersize => 'lasdf', 'generic'],
                 [ papersize => 'a4', 'a4'],
                 [ division => '4', 12],
                 [ division => '15', 15],
                 [ fontsize => '9', 10],
                 [ fontsize => '12', 12],
                 [ fontsize => '10.5', 12],
                 [ bcor => '', '0'],
                 [ bcor => 'blabla', '0'],
                 [ bcor => '10', '10'],
                 [ mainfont => 'Charis SIL', 'Charis SIL'],
                 [ mainfont => 'Linux Libertine O', 'Linux Libertine O'],
                 [ mainfont => '\hello', 'Linux Libertine O'],
                );
foreach my $try (@accessors) {
    my $method   = $try->[0];
    my $input    = $try->[1];
    my $expected = $try->[2];
    try {
        $bb->$method($input);
    } catch {
        my $msg = $_->message;
        chomp $msg;
        diag $msg;
    };
    my $show = Dumper($expected);
    chomp $show;
    is ($bb->$method, $expected, "$method returned $show");
}

my %params = (
              twoside => '\hello',
              garbage => 'lkjasdfl',
              schifo  => '\\\\\\\\bla',
              papersize => 'A4',
              fontsize => 10,
              bcor => 20,
              mainfont => 'CMU Serif',
              division => '8',
              schema => '2up',
              imposed => 1,
              nocoverpage => '\\x',
              cover => '',
              signatures => 1,
             );



eval { $bb->schema('2x4x2x') };
my $err = $@;

ok($err->message, "Found error") and diag $err->message;

eval { $bb->schema('2x4x2') };

ok(!$@, "No error");

eval { $bb->papersize('blablabla') };
ok($@, "Error found") and diag $@->message;


eval { $bb->papersize('a4') };
ok(!$@, "No error");

diag Dumper($bb);


my $expected = {
                'text_list' => [
                                'appended',
                                'pippo'
                               ],
                'imposer_options' => {
                                      'signature' => '40-80',
                                      'schema' => '2up',
                                      'cover'  => '1',
                                     },
                'template_options' => {
                                       'bcor' => '20mm',
                                       'nocoverpage' => 1,
                                       'notoc' => 1,
                                       'mainfont' => 'CMU Serif',
                                       'twoside' => 1,
                                       'division' => 14,
                                       'fontsize' => 10,
                                       'coverwidth' => '0.85',
                                       'papersize' => 'a4',
                                       'cover' => undef,
                                      },
                'title' => 'Pippuzzo va in montagna'
               };


%params = (
           title       => 'Pippuzzo va in montagna',
           mainfont    => 'CMU Serif',
           fontsize    => '10',
           papersize   => 'a4',
           division    => '14',
           bcor        => '20',
           coverwidth  => '85',
           twoside     => 1,
           notoc       => 1,
           nocoverpage => 1,
           imposed     => 1,
           signature   => '40-80',
           schema      => '2up',
           cover       => 1,
           # coverimage should be called with add_file
          );

$bb = AmuseWikiFarm::Archive::BookBuilder->new;

foreach my $text (qw/appended pippo/) {
    ok($bb->add_text($text), "$text added");
}

$bb->import_from_params(%params);

is_deeply ($bb->as_job, $expected, "Output correct");

my $newbb = AmuseWikiFarm::Archive::BookBuilder->new(%{$bb->constructor_args});

is_deeply ($bb->as_job, $newbb->as_job, "Old and new have the same output");

is($bb->as_job->{title}, $params{title});

%params = (
           title       => 'Pippuzzo va in montagna',
           mainfont    => 'CMU Serif',
           fontsize    => '10',
           papersize   => 'a4',
           division    => '14',
           bcor        => '20',
           coverwidth  => '85',
           twoside     => 1,
           notoc       => 1,
           nocoverpage => 1,
           imposed     => 1,
           signature   => '40-80',
           signature_4up => '8',
           schema      => '2up',
           cover       => 1,
           # coverimage should be called with add_file
          );

$bb->import_from_params(%params);
is $bb->signature, '40-80', "Signature_4up ignored with schema 2up";


%params = (
           title       => 'Pippuzzo va in montagna',
           mainfont    => 'CMU Serif',
           fontsize    => '10',
           papersize   => 'a4',
           division    => '14',
           bcor        => '20',
           coverwidth  => '85',
           twoside     => 1,
           notoc       => 1,
           nocoverpage => 1,
           imposed     => 1,
           signature   => '4',
           signature_4up => '16',
           schema      => '4up',
           cover       => 1,
           # coverimage should be called with add_file
          );

$bb->import_from_params(%params);
is $bb->signature, 16, "Signature_4up picked up with 4up schema";
