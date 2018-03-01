#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 1;
use Data::Dumper::Concise;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

my $site_id = '0facets0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

{
    my $file = path($site->repo_root, qw/t t1 test1.muse/);
    $file->parent->mkpath;
    my $muse = <<'MUSE';
#title First test
#topics kuća, snijeg, škola, peć
#authors pinkić palinić, kajo šempronijo
#pubdate 2013-12-25
#lang en

** This is a book common

** Because it has sectioning

MUSE
    $file->spew_utf8($muse);
}


{
    my $file = path($site->repo_root, qw/t t2 test2.muse/);
    $file->parent->mkpath;
    my $muse = <<'MUSE';
#title Second test
#topics kuća, snijeg, škola, peć, xkuća, xsnijeg, xškola, xpeć, hullo
#authors apinkić apalinić, akajo ašempronijo, pinkić palinić, kajo šempronijo, hey
#pubdate 2009-12-25
#lang en

This is not a book common

This is an article

MUSE
    $file->spew_utf8($muse);
}

{
    my $file = path($site->repo_root, qw/t t3 test3.muse/);
    $file->parent->mkpath;
    my $muse = <<'MUSE';
#title Third test
#topics xkuća, xsnijeg, xškola, xpeć
#authors apinkić apalinić, akajo ašempronijo
#pubdate 2017-12-25
#lang hr

This is a very long piece common

MUSE

    my $lorem = <<'LOREM';

Sed ut perspiciatis unde omnis iste natus error sit voluptatem
accusantium doloremque laudantium, totam rem aperiam, eaque ipsa
quae ab illo inventore veritatis et quasi architecto beatae vitae
dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit
aspernatur aut odit aut fugit, sed quia consequuntur magni dolores
eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam
est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci
velit, sed quia non numquam eius modi tempora incidunt ut labore
et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima
veniam, quis nostrum exercitationem ullam corporis suscipit
laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem
vel eum iure reprehenderit qui in ea voluptate velit esse quam
nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo
voluptas nulla pariatur


Što je Lorem Ipsum?

Lorem Ipsum je jednostavno probni tekst koji se koristi u tiskarskoj i
slovoslagarskoj industriji. Lorem Ipsum postoji kao industrijski
standard još od 16-og stoljeća, kada je nepoznati tiskar uzeo
tiskarsku galiju slova i posložio ih da bi napravio knjigu s uzorkom
tiska. Taj je tekst ne samo preživio pet stoljeća, već se i vinuo u
svijet elektronskog slovoslagarstva, ostajući u suštini nepromijenjen.
Postao je popularan tijekom 1960-ih s pojavom Letraset listova s
odlomcima Lorem Ipsum-a, a u skorije vrijeme sa software-om za stolno
izdavaštvo kao što je Aldus PageMaker koji također sadrži varijante
Lorem Ipsum-a. Zašto ga koristimo?

Odavno je uspostavljena činjenica da čitača ometa razumljivi tekst dok
gleda raspored elemenata na stranici. Smisao korištenja Lorem Ipsum-a
jest u tome što umjesto 'sadržaj ovjde, sadržaj ovjde' imamo normalni
raspored slova i riječi, pa čitač ima dojam da gleda tekst na
razumljivom jeziku. Mnogi programi za stolno izdavaštvo i uređivanje
web stranica danas koriste Lorem Ipsum kao zadani model teksta, i ako
potražite 'lorem ipsum' na Internetu, kao rezultat dobit ćete mnoge
stranice u izradi. Razne verzije razvile su se tijekom svih tih
godina, ponekad slučajno, ponekad namjerno (s dodatkom humora i
slično). LOREM

LOREM
    $file->spew_utf8($muse, $lorem x 20);
}

$site->update_db_from_tree(sub { diag @_ });

my $res = $site->xapian->faceted_search(query => "is");
diag Dumper($res);
is $res->pager->total_entries, 3;

