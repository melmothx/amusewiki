#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 50;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Path::Tiny;
use AmuseWikiFarm::Utils::LexiconMigration;
use Locale::PO;
use Data::Dumper;

my $temp = Path::Tiny->tempdir;
my $lexicon = {
               'is "this" a good day?' => {
                                           it => 'È "questo" un buon giorno?',
                                           hr => 'Da li je "ovo" dobar dan?',
                                          },
               '' => {},
              };

AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");

my %checks;

foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    ok ($po->exists);
    my $content = $po->slurp_utf8;
    my $key = my $key_expected = 'is "this" a good day?';
    $key_expected =~ s/"/\\"/g;
    my $val = $lexicon->{$key}->{$lang};
    $val =~ s/"/\\"/g;
    like $content, qr{msgid "\Q$key_expected\E"};
    like $content, qr{msgstr "\Q$val\E"};
    like $content, qr{charset=UTF-8};
    like $content, qr{Language: $lang};
    $checks{$lang} = [ qr{msgid "\Q$key_expected\E"}, qr{msgstr "\Q$val\E"}, qr{charset=UTF-8},
                       qr{Language: $lang},
                     ];
}

$lexicon->{test} = {
                    it => 'Prova ć',
                    hr => 'Proba ò',
                   };

AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    ok ($po->exists);
    my $content = $po->slurp_utf8;
    foreach my $check (@{$checks{$lang}}) {
        like $content, $check, "Updated PO has old content $check";
    }
    like $content, qr{msgstr "$lexicon->{test}->{$lang}"}, "New string came in";
    push @{$checks{$lang}}, qr{msgstr "$lexicon->{test}->{$lang}"};
}

$lexicon->{newtest} = {};

AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    my $content = $po->slurp_utf8;
    foreach my $check (@{$checks{$lang}}) {
        like $content, $check, "Updated PO has old content $check";
    }
    like $content, qr{msgid "newtest"\nmsgstr ""}, "new key in lexicon generate new po entries";
    push @{$checks{$lang}}, qr{msgid "newtest"\nmsgstr ""};
}

delete $lexicon->{test};
print Dumper($lexicon);
AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    ok ($po->exists);
    my $content = $po->slurp_utf8;
    foreach my $check (@{$checks{$lang}}) {
        like $content, $check, "Updated PO has old content $check, deletion from lexicon has no effect";
    }
}

$lexicon->{test} = {
                    it => 'bla',
                   };
AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
{
    my $po = path($temp, 'it.po');
    my $content = $po->slurp_utf8;
    like $content, qr{msgid "test"\nmsgstr "bla"};
}
{
    my $po = path($temp, 'hr.po');
    my $content = $po->slurp_utf8;
    like $content, qr{msgid "test"\nmsgstr "Proba ò"};
}



# ...to be continued
