#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 64;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Path::Tiny;
use AmuseWikiFarm::Utils::LexiconMigration;
use AmuseWikiFarm::Archive::Lexicon;
use Locale::PO;
use Data::Dumper;

my $temp_root = Path::Tiny->tempdir;
my $temp = path($temp_root, qw/amw site_files locales/);
$temp->mkpath;

my $lexicon = {
               'is %1 "this" a good %2 day?' => {
                                                 it => 'È "questo" %1 un buon giorno %2?',
                                                 hr => 'Da ć li je %1 "ovo" dobar dan %2?',
                                                },
               '' => {},
              };

my $lexicon_orig = {
                    'is [_1] "this" a good [_2] day?' => {
                                                          it => 'È "questo" [_1] un buon giorno [_2]?',
                                                          hr => 'Da ć li je [_1] "ovo" dobar dan [_2]?',
                                          },
               '' => {},
              };

my $model = AmuseWikiFarm::Archive::Lexicon->new(system_wide_po_dir => path(qw/lib AmuseWikiFarm I18N/)
                                                 ->absolute->stringify,
                                                 repo_dir => $temp_root->stringify);

AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon_orig, "$temp");

my %checks;

foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    ok ($po->exists);
    my $content = $po->slurp_utf8;
    my $key = my $key_expected = 'is %1 "this" a good %2 day?';
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
is $model->localizer(qw/it amw/)->loc('is [_1] "this" a good [_2] day?'),
  'È "questo"  un buon giorno ?';
is $model->localizer(qw/hr amw/)->loc('is [_1] "this" a good [_2] day?'),
  'Da ć li je  "ovo" dobar dan ?';


$lexicon->{test} = {
                    it => 'Prova ć',
                    hr => 'Proba ò',
                   };

sleep 1;
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
    diag $po->stat->mtime . ' vs ' . time();
    is $model->localizer($lang, 'amw')->loc('test'), $lexicon->{test}->{$lang},
      "'test' translated ok";
}

$lexicon->{newtest} = {};

sleep 1;
AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    my $content = $po->slurp_utf8;
    foreach my $check (@{$checks{$lang}}) {
        like $content, $check, "Updated PO has old content $check";
    }
    like $content, qr{msgid "newtest"\nmsgstr ""}, "new key in lexicon generate new po entries";
    push @{$checks{$lang}}, qr{msgid "newtest"\nmsgstr ""};
    is $model->localizer($lang, 'amw')->loc('test'), $lexicon->{test}->{$lang},
      "'test' translated ok";
    is $model->localizer($lang, 'amw')->loc('newtest'), "newtest";
}

my $removed = delete $lexicon->{test};
sleep 1;
AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
foreach my $lang (qw/it hr/) {
    my $po = path($temp, $lang . '.po');
    ok ($po->exists);
    my $content = $po->slurp_utf8;
    foreach my $check (@{$checks{$lang}}) {
        like $content, $check, "Updated PO has old content $check, deletion from lexicon has no effect";
    }
    is $model->localizer($lang, 'amw')->loc('test'), $removed->{$lang},
      "'test' translated ok";
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

$lexicon->{test} = {
                    it => '',
                   };
sleep 1;
AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");
{
    my $po = path($temp, 'it.po');
    my $content = $po->slurp_utf8;
    like $content, qr{msgid "test"\nmsgstr "bla"};
    is $model->localizer(qw/it amw/)->loc('test'), "bla";
}
{
    my $po = path($temp, 'hr.po');
    my $content = $po->slurp_utf8;
    like $content, qr{msgid "test"\nmsgstr "Proba ò"};
    is $model->localizer(qw/hr amw/)->loc('test'), "Proba ò";
}

