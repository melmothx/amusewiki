#!perl

use strict;
use warnings;
use AmuseWikiFarm::Archive::Lexicon;
use Test::More tests => 38;
use Path::Tiny;
use Data::Dumper;
eval q{use Test::Memory::Cycle;};
my $no_cycle = 0;
if ($@) {
    $no_cycle = 1;
}

my $path = path(qw/lib AmuseWikiFarm I18N/);
my $model = AmuseWikiFarm::Archive::Lexicon->new(
                                                 system_wide_po_dir => "$path",
                                                 repo_dir => "repo",
                                                );
ok($model);
for (1..2) {
    {
        my $l = $model->localizer('it');
        is $l->loc('Active'), "Attivo";
        is $l->loc("[_1] doesn't exist", "Pippo"), "Pippo non esiste";
    }
    {
        my $l = $model->localizer('en');
        is $l->loc('Active'), "Active";
        is $l->loc("[_1] doesn't exist", "Pippo"), "Pippo doesn't exist";
    }
}


my $additional = path(qw/repo 0blog0 site_files locales/);
$additional->mkpath unless $additional->exists;
my $po_chunck = <<PO;
msgid "%1 doesn't exist"
msgstr "%1 'proprio' non <esiste>"

PO
path($additional, 'it.po')->spew($po_chunck);

for (1..2) {
    {
        my $l = $model->localizer('it', '0blog0');
        is $l->loc("[_1] doesn't exist", "Pippo"), "Pippo 'proprio' non <esiste>";
        is $l->loc_html("[_1] doesn&apos;t exist", "Pippo"), "Pippo &#39;proprio&#39; non &lt;esiste&gt;";
        is $l->loc('Active'), "Attivo";
        is $l->loc('asdfasdfasdf'), 'asdfasdfasdf';
        my $verbatim = q{"&'<>"&'<>};
        my $escaped = "&quot;&amp;&#39;&lt;&gt;&quot;&amp;&#39;&lt;&gt;";
        is $l->loc($verbatim), $verbatim, "loc($verbatim) is $verbatim (nothing changes)";
        is $l->loc($escaped), $verbatim, "loc($escaped) is $verbatim (unescaped)";
        is $l->loc_html($verbatim), $escaped, "loc_html($verbatim) is $escaped (escaped)";
        is $l->loc_html($escaped), $escaped, "loc_html($escaped) is $escaped (nothing changes)";
    }
    {
        my $l = $model->localizer('it');
        is $l->loc("[_1] doesn't exist", "Pippo"), "Pippo non esiste";
        is $l->loc('Active'), "Attivo";
        is $l->loc('asdfasdfasdf'), 'asdfasdfasdf';
        is $l->loc('Active'), 'Attivo';
    }
    {
        # loading this means the code is buggy.
        my $l = eval { $model->localizer('xx', '0blog0') };
        ok (!$l, "Couldn't load xx language");
        ok $@, "Exception raised";
    }
}
SKIP: {
    skip "No Test::Memory::Cycle", 1 if $no_cycle;
    memory_cycle_ok($model, "Model is memory cycle free");
}

# diag Dumper($model);
