#!perl

use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use Data::Dumper;

use Test::More tests => 8;


use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWikiFarm::Utils::Amuse qw/muse_file_info/;


my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

my @warns;
$SIG{__WARN__} = sub {
    push @warns, @_;
};



my $muse = <<MUSE;
#title Мемуары
#author Луиза Мишель
#SORTtopics революция, мемуары, коммуна, Парижская Коммуна, история
#source Свобода и труд. Анархизм и синдикализм. Сб. 1. — СПб. : Волна, 1907.
#lang ru Перев. с французского

*** От редакции

«Мемуары», написанные знаменитой анархисткой Луизой Мишель, носят
в подлиннике весьма отрывочный характер. В своем рассказе Мишель часто
не считается с хронологической последовате льностью, делает
пространные отступления, пересыпает страницы своих мемуаров своими
стихотворениями, не имеющими ни исторической, ни литературной
ценности.

MUSE

my $file = catfile(qw/t repotest a at a-test-lang-borked.muse/);

write_file($file, $muse);

my $repo_root = catdir(qw/t repotest/);

my $details = muse_file_info($file, $repo_root);

is ($details->{lang}, 'ru', "Language extracted from garbage");

$muse = <<MUSE;
#title Мемуары
#author Луиза Мишель
#SORTtopics революция, мемуары, коммуна, Парижская Коммуна, история
#source Свобода и труд. Анархизм и синдикализм. Сб. 1. — СПб. : Волна, 1907.

*** От редакции

«Мемуары», написанные знаменитой анархисткой Луизой Мишель, носят
в подлиннике весьма отрывочный характер. В своем рассказе Мишель часто
не считается с хронологической последовате льностью, делает
пространные отступления, пересыпает страницы своих мемуаров своими
стихотворениями, не имеющими ни исторической, ни литературной
ценности.

MUSE

write_file($file, $muse);

$details = muse_file_info($file, $repo_root);

is ($details->{lang}, 'en', "No lang, default to en");


$muse = <<MUSE;
#title Мемуары
#author Луиза Мишель
#SORTtopics революция, мемуары, коммуна, Парижская Коммуна, история
#source Свобода и труд. Анархизм и синдикализм. Сб. 1. — СПб. : Волна, 1907.
#lang Перев. с французского

*** От редакции

«Мемуары», написанные знаменитой анархисткой Луизой Мишель, носят
в подлиннике весьма отрывочный характер. В своем рассказе Мишель часто
не считается с хронологической последовате льностью, делает
пространные отступления, пересыпает страницы своих мемуаров своими
стихотворениями, не имеющими ни исторической, ни литературной
ценности.

MUSE

write_file($file, $muse);

$details = muse_file_info($file, $repo_root);

is ($details->{lang}, 'en', "No lang, default to en");


$muse = <<MUSE;
#title Мемуары
#author Луиза Мишель
#SORTtopics революция, мемуары, коммуна, Парижская Коммуна, история
#source Свобода и труд. Анархизм и синдикализм. Сб. 1. — СПб. : Волна, 1907.
#lang    ru  

*** От редакции

«Мемуары», написанные знаменитой анархисткой Луизой Мишель, носят
в подлиннике весьма отрывочный характер. В своем рассказе Мишель часто
не считается с хронологической последовате льностью, делает
пространные отступления, пересыпает страницы своих мемуаров своими
стихотворениями, не имеющими ни исторической, ни литературной
ценности.

MUSE

write_file($file, $muse);

$details = muse_file_info($file, $repo_root);

is ($details->{lang}, 'ru', "Lang correctly set");


is scalar(@warns), 3, "3 warns found";

like $warns[0], qr/Language.*found, using .* instead/,
  "Warning found for cleaning";
like $warns[1], qr/No language found, assuming english/,
  "Warning found for no lang";
like $warns[2], qr/Garbage .* found in #lang, using "en" instead/,
  "Warning found for garbage";



unlink $file or die $!;

