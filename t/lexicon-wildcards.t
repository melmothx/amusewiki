#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 120;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";
use constant { DEBUG => 1 };

use Path::Tiny;
use AmuseWikiFarm::Utils::LexiconMigration;
use AmuseWikiFarm::Archive::Lexicon;
use Locale::PO;
use Data::Dumper;
use AmuseWikiFarm::Utils::Amuse ();

my $temp_root = Path::Tiny->tempdir(CLEANUP => !DEBUG);
my $temp = path($temp_root, qw/amw site_files locales/);
$temp->mkpath;

my $lexicon = {
               'is %1 "this" a good %2 day?' => {
                                                 it => 'È "questo" %1 un buon giorno %2?',
                                                 hr => 'Da ć li je %1 "ovo" dobar dan %2?',
                                                },
               'dft' => {
                           'it' => 'Bozze',
                           '*' => 'Draft',
                          },
               'tst' => {
                         '*' => 'Test',
                        },
              };

AmuseWikiFarm::Utils::LexiconMigration::convert($lexicon, "$temp");

my $model = AmuseWikiFarm::Archive::Lexicon->new(repo_dir => $temp_root->stringify);

diag "Using $temp_root";

my $langs = AmuseWikiFarm::Utils::Amuse::known_langs();

foreach my $lang (keys %$langs) {
    next if $lang eq 'it' || $lang eq 'hr';
    diag "Testing $lang";
    my $lh = $model->localizer($lang, 'amw');
    is $lh->loc('dft'), 'Draft';
    is $lh->loc('tst'), 'Test';
    is $lh->loc('is [_1] "this" a good [_2] day?', ['one', 'two']),
      q{is one "this" a good two day?};
    is $lh->site_loc('dft'), 'Draft';
    is $lh->site_loc('tst'), 'Test';

    is $lh->site_loc('is [_1] "this" a good [_2] day?', 'one', 'two'),
      q{is one "this" a good two day?}, "Site loc for $lang interpolates";
}

{
    my $lh = $model->localizer(qw/it amw/);
    is $lh->loc('dft'), 'Bozze';
    is $lh->loc('tst'), 'Test';
    is $lh->loc('is [_1] "this" a good [_2] day?', ['one', 'two']),
      q{È "questo" one un buon giorno two?};
    is $lh->site_loc('dft'), 'Bozze';
    is $lh->site_loc('tst'), 'Test';
    is $lh->site_loc('is [_1] "this" a good [_2] day?', 'one', 'two'),
      q{È "questo" one un buon giorno two?};
}
{
    my $lh = $model->localizer(qw/hr amw/);
    is $lh->loc('dft'), 'Draft';
    is $lh->loc('tst'), 'Test';
    is $lh->loc('is [_1] "this" a good [_2] day?', ['one', 'two']),
      q{Da ć li je one "ovo" dobar dan two?};
    is $lh->site_loc('dft'), 'Draft';
    is $lh->site_loc('tst'), 'Test';
    is $lh->site_loc('is [_1] "this" a good [_2] day?', 'one', 'two'),
      q{Da ć li je one "ovo" dobar dan two?};
}
