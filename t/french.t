#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 12;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper::Concise;
use Path::Tiny;

use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0fr0');

my $french = <<'MUSE';
dans une adoration acritique des « ancêtres », des « formes traditionnelles »
« Tout disparaîtra mais… le vent nous portera. »
Tu parles! Tu parles? Tu parles:
dans une adoration acritique des «ancêtres», des «formes traditionnelles»
MUSE

my ($rev_fr) = $site->create_new_text({
                                       uri => "french-fr",
                                       title => $french,,
                                       subtitle => $french,
                                       notes => $french,
                                       textbody => $french,
                                       author => 'my first!',
                                       SORTauthors => 'my first! ; «formes»',
                                       SORTtopics => 'xmy first! ; «xformes»',
                                       lang => "fr",
                                      }, 'text');
$rev_fr->commit_version;
$rev_fr->publish_text;
my $fr = $rev_fr->title;

my ($rev_en) = $site->create_new_text({
                                       uri => "french-en",
                                       title => $french,,
                                       subtitle => $french,
                                       notes => $french,
                                       textbody => $french,
                                       lang => "en",
                                       author => 'my first!',
                                       SORTauthors => 'xmy first! ; «xformes»',
                                       SORTtopics => 'xxmy first! ; «xxformes»',
                                      }, 'text');
$rev_en->commit_version;
$rev_en->publish_text;
my $en = $rev_en->title;

foreach my $m (qw/title subtitle notes author/) {
    isnt $en->$m, $fr->$m;
    diag $fr->$m;
    diag $en->$m;
}

like $fr->authors->find({ uri => 'my-first' })->name, qr/\x{202f}/;
like $fr->authors->find({ uri => 'formes' })->name, qr/\x{ab}\x{a0}/;

unlike $en->authors->find({ uri => 'xmy-first' })->name, qr/\x{202f}/;
unlike $en->authors->find({ uri => 'xformes' })->name, qr/\x{ab}\x{a0}/;

like $fr->topics->find({ uri => 'xmy-first' })->name, qr/\x{202f}/;
like $fr->topics->find({ uri => 'xformes' })->name, qr/\x{ab}\x{a0}/;

unlike $en->topics->find({ uri => 'xxmy-first' })->name, qr/\x{202f}/;
unlike $en->topics->find({ uri => 'xxformes' })->name, qr/\x{ab}\x{a0}/;




diag Dumper();
