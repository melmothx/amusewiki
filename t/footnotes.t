#!perl

use utf8;
use strict;
use warnings;
use Data::Dumper::Concise;
use AmuseWikiFarm::Utils::Footnotes;
use Test::More;

my $muse = <<'EOF';
#title test
#lang it

  Ed elli a me [1]: «La tua città, {3} ch'è piena
d'invidia sí che già [2] trabocca il sacco,
seco mi tenne in la vita [3] serena.
  Voi cittadini mi chiamaste Ciacco:
per la dannosa colpa [1] [3] della gola,
come tu vedi, alla pioggia mi fiacco.
  E io anima trista non son [1]  sola,
ché tutte queste a simil pena stanno
per simil colpa». E piú non fe' [1] parola.
  Io li rispuosi: «Ciacco, il tuo affanno
mi pesa sí ch'a [1] lagrimar mi 'nvita;
ma dimmi, se tu sai, a che verranno
  li cittadin della [1] città partita;
s'alcun v'è giusto; e dimmi la cagione
per che l'ha tanta discordia assalita».

[1] Ed elli a me: «Dopo lunga tencione

[1] Verranno al sangue, e la parte selvaggia

[1] Caccerà l'altra con molta offensione.

[1] Poi appresso convien che questa caggia

[1] Infra tre soli, e che l'altra sormonti

[1] Con La forza di tal che testé piaggia.

[1] Alte terrà lungo tempo le fronti,

[1] Tenendo l'altra sotto gravi pesi,

[1] Come che di ciò pianga o che n'adonti.

[1] Giusti son due, e non vi sono intesi:

{{{
Test [1]

[1] pizza
}}}

{3} Secondary

EOF

my $reporter = AmuseWikiFarm::Utils::Footnotes->new(muse_body => $muse);
my $report = $reporter->report;
ok $report->{body_primary};
diag Dumper($report);
my $list = $reporter->report_as_list;
ok $list->{primary};
diag Dumper($list);
done_testing;
