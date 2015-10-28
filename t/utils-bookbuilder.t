use strict;
use warnings;
use utf8;
use Test::More tests => 112;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
# use Test::Memory::Cycle;
use JSON qw/to_json from_json/;
use Try::Tiny;
use CAM::PDF;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use AmuseWikiFarm::Schema;

use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid muse_naming_algo/;
use AmuseWikiFarm::Archive::BookBuilder;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 999998,
                                                      });
    cleanup($bb->job_id);
    $bb->mainfont('TeX Gyre Pagella');

    for (1..2) {
        $bb->add_text('first-test');
        my $pdffile = File::Spec->catfile($bb->rootdir, $bb->customdir,
                                          $bb->compile);
        my $pdf = CAM::PDF->new($pdffile);
        my ($font) = ($pdf->getFonts(1));
        ok $font->{BaseFont}->{value},
          "Found font name: $font->{BaseFont}->{value}";
        like $bb->mainfont, qr/Pagella/;
        like $font->{BaseFont}->{value}, qr/Pagella/, "Font is correct";
    }
}

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
                 [ fontsize => '8', 10],
                 [ fontsize => '12', 12],
                 [ fontsize => '10.5', 12],
                 [ bcor => '', '0'],
                 [ bcor => 'blabla', '0'],
                 [ bcor => '10', '10'],
                 [ mainfont => 'Charis SIL', 'Charis SIL'],
                 [ mainfont => 'Linux Libertine O', 'Linux Libertine O'],
                 [ mainfont => '\hello', 'Linux Libertine O'],
                 [ opening => '\\blabla', 'any' ],
                 [ opening => 'right', 'right' ],
                 [ opening => 'any', 'any' ],
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
                                       sansfont    => 'CMU Sans Serif',
                                       monofont    => 'CMU Typewriter Text',
                                       beamertheme => 'default',
                                       beamercolortheme => 'dove',
                                       'twoside' => 1,
                                       'division' => 14,
                                       'fontsize' => 10,
                                       'coverwidth' => '0.85',
                                       'papersize' => 'a4',
                                       'cover' => undef,
                                       opening => 'right',
                                      },
                'title' => 'Pippuzzo *va* in **montagna**'
               };


my %params = (
              title       => 'Pippuzzo *va* in **montagna**',
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
              # coverfile should be called with add_file
              coverfile   => 'garbage',
              opening     => 'right',
          );

$bb = AmuseWikiFarm::Archive::BookBuilder->new;

foreach my $text (qw/appended pippo/) {
    ok($bb->add_text($text), "$text added");
}

$bb->import_from_params(%params);
is $bb->coverfile, undef, 'coverfile not imported';

is_deeply ($bb->as_job, $expected, "Output correct");

my $newbb = AmuseWikiFarm::Archive::BookBuilder->new(%{$bb->serialize});

is_deeply ($bb->as_job, $newbb->as_job, "Old and new have the same output");

is($bb->as_job->{title}, $params{title});

is ($bb->opening, 'right');

%params = (
           title       => 'Pippuzzo *va* in **montagna**',
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
           opening     => 'any',
           # coverimage should be called with add_file
          );

$bb->import_from_params(%params);
is $bb->signature, '40-80', "Signature_4up ignored with schema 2up";
is $bb->opening, 'any';

%params = (
           title       => 'Pippuzzo *va* in **montagna**',
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
           opening     => '<em>',
           format => 'pdf',
          );

$bb->import_from_params(%params);
is $bb->signature, 16, "Signature_4up picked up with 4up schema";
is $bb->opening, 'any', "Opening set to any because of invalid input";

$bb->import_from_params();
is $bb->imposed, undef, "imposed nulled out with empty params";
is $bb->mainfont, 'CMU Serif', "mainfont kept with empty params";
is $bb->notoc, undef, "notoc set to undef";
is $bb->twoside, undef, "twoside set to undef";

$bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                dbic => $schema,
                                                site_id => '0blog0',
                                                job_id => 999999,
                                               });

is ($bb->site_id, '0blog0', "Object ok");
is ($bb->site->id, '0blog0', "site built");

foreach my $text ($bb->site->titles->published_texts) {
    ok ($bb->add_text($text->uri), "Added " . $text->uri);
    ok (!$bb->error, "No error found") or diag $bb->error;
}
ok (!$bb->add_text('this-does-not-exists'));
ok ($bb->error, "Found error: " . $bb->error);

ok ($bb->total_pages_estimated,
    "Found page estimated: " . $bb->total_pages_estimated);

is_deeply ($bb->texts,
           [
            'first-test',
            'second-test',
            'do-this-by-yourself',
           ], "List ok");

$bb->format('epub');
check_file($bb, "epub");

$bb->import_from_params(%params);
ok (!$bb->epub);
# readd
$bb->delete_text(3);
foreach my $text(qw/first-test do-this-by-yourself/) {
    ok ($bb->add_text($text), "Added $text again") or diag $bb->error;
}
ok ($bb->imposed, "Imposing required");
$bb->schema('2up');
$bb->signature(0);
$bb->cover(1);
check_file($bb, "imposed one");
cleanup($bb->job_id);

ok ($bb->webfonts_rootdir);
ok ($bb->webfonts) and diag Dumper($bb->webfonts);

sub check_file {
    my ($bb, $msg) = @_;
    my $out = $bb->compile;
    ok ($out, "$msg: $out produced");
    my $file = File::Spec->catfile($bb->rootdir, $bb->customdir, $out);
    ok (-f $file, "$msg: $out: $file exists");
    foreach my $f ($bb->produced_files) {
        ok (-f $f, "$msg: $f exists");
    }
    # unlink $file or die $1;
}

sub cleanup {
    my $id = shift;
    my @files = ("$id.pdf", "$id.epub", "bookbuilder-$id.zip");
    foreach my $file (@files) {
        my $path = File::Spec->catfile(qw/root custom/, $file);
        if (-f $path) {
            diag "removing $path";
            unlink $path or die $!;
        }
    }
}
