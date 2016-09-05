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
use Test::More tests => 42;
use Data::Dumper;
use File::Path qw/make_path/;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";


my $site_id = '0xapian0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);


diag $site->repo_root;
ok ($site->xapian);
make_path(   catdir( $site->repo_root, qw/t tt/));
my $target = catfile($site->repo_root, qw/t tt test.muse/);

write_file($target, "#title XXXX\n#SORTtopics prova\n\nBla bla");
write_file(catfile($site->repo_root, qw/uploads test.pdf/),
           "PDF");
write_file(catfile($site->repo_root, qw/t tt test.png/),
           "PNG");

$site->update_db_from_tree(sub { diag @_ });
is $site->titles->count, 1, "1 title now";
is $site->attachments->count, 2, "2 attachments";
is $site->categories->count, 1, "1 category";
is $site->categories->first->text_count, 1, "1 category, 1 text";
my $xapian_dir = $site->xapian->xapian_dir;
ok (-d $xapian_dir, "$xapian_dir exists");


for my $term ('XXXX', 'bla') {
    my ($total, @results) = $site->xapian->search(qq{"$term"});
    is($total->last, 1, "one result, of course");
    is($total->first, 1, "one result, of course");
    ok(@results == 1, "Found 1 result with $term");
    is $results[0]{pagename}, "test", "Found the doc";
}

for my $removal ($target,
                 catfile($site->repo_root, qw/uploads test.pdf/),
                 catfile($site->repo_root, qw/t tt test.png/)) {
    unlink $removal or die "couldn't unlink $removal $!";
}

$site->update_db_from_tree;
is $site->titles->count, 0, "0 titles now";
is $site->attachments, 0, "0 attachments";
is $site->categories->first->text_count, 0, "1 category, but empty";

for my $term ('XXXX', 'bla') {
    my ($total, @results) = $site->xapian->search(qq{"$term"});
    is($total->last, 0, "one result after deletion");
    is($total->first, 0, "one result after deletion");
    ok(@results == 0, "Found 0 result with $term");
}
eval { $site->xapian->xapian_db->delete_document_by_term("Qtest") };
ok !$@, "No exception deleting an already deleted doc";

write_file($target, "#title XXXX#lang fr\n#SORTtopics prova\n\nBla bla État\n");
$site->update_db_from_tree;
foreach my $term ("état", "etat", "ÉTAT", "ETAT") {
    my ($total, @results) = $site->xapian->search($term);
    is $total->total_entries, 1, "Found one record searching for $term";
}

my $russian =<<MUSE;
#title Russian
#lang ru

 Среди множества героических натур, отдавших свои силы и жизнь на
 служение анархизму, одной из самых благородных, чистых и
 самоотверженных представляется нам фигура итальянского анархиста
 Малатесты.

Даже в той среде, где слово обыкновенно никогда не расходится с делом,
Малатеста пользуется совершенно исключительной любовью и уважением.
Эти чувства являются достойным венцом его апостольской проповеди и
самоотверженной жизни.

Никакие преследования, никакие гонения не могли остановить Малатесты,
когда он выступал на служение своей любимой идее. Всевозможные кары со
стороны разных правительств градом сыпались на голову Малатесты, а он
неуклонно шел вперед, веря в лучшие времена, в торжество конечной
эмансипации человеческой личности.

Малатеста — героическая натура, не выносящая никаких компромиссов,
равно вступающая в борьбу с либеральными парламентами, судом и
печатью, как и с умеренными социалистами, предпочитающими сомнительные
союзы неудержному и непримиримому движению вперед.

В этом отношении особенно замечателен ожесточенный поход, открытый им
против социалистов совместно с сотоварищем и другом Кофиеро после
позорного Лондонского конгресса 1887 г., закончившегося изгнанием
анархистов.

MUSE

write_file($target, $russian);
$site->update_db_from_tree;
$site->xapian_reindex_all;
foreach my $term ('умеренными', '1887', 'ravno', 'protiv', 'ИЗГНАНИЕМ',
                  'kofiero', 'малатеста') {
    my ($total, @results) = $site->xapian->search($term, 1, 'ru');
    is $total->total_entries, 1, "Found one record searching for $term";
}
foreach my $term ('xxxумеренными', 'x1887x', 'xravnox', 'xprotivx', 'xxИЗГНАНИЕМxx',
                  'xkofierox', 'xмалатестаx') {
    my ($total, @results) = $site->xapian->search($term, 1, 'ru');
    is $total->total_entries, 0, "Found no record searching for $term";
}




