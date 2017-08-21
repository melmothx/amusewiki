#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 3;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use DateTime;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0diff0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });
my $with_hyphens =<<'EOF';
#title Pallino
#author pinco
#lang ru

Этот принцип абсолюта» противоположен принципу, призна­ваемому
идеалистами всех школ. В то время как последние вы­водят всю историю —
включая проявление материальных инте­ресов и различных ступеней
экономической организации общест­ва — из проявления идей, немецкие
коммунисты, напротив, во всей человеческой истории, в самых идеальных
проявлениях как коллективной, так и индивидуальной жизни человечества,
во всех интеллектуальных, моральных, религиозных, метафизиче­ских,
научных, художественных, политических, юридических и социальных
проявлениях, имевших место в прошлом и происхо­дящих в настоящем,
видели лишь отражение или неизбежный рикошет проявления экономических
фактов. В то время как идеалисты утверждают, что идеи господствуют над
фактами и производят их, коммунисты, наоборот, в полном согласии с
на­учным материализмом утверждают, что факты порождают идеи и что
последние всегда лишь суть идеальное отражение совер­шившихся фактов,
что из всех фактов факты экономические, материальные, факты по
преимуществу представляют собой настоящую базу, главное основание;
всякие же другие факты — интеллектуальные и моральные, политические и
социальные — суть лишь необходимо производные.¶

EOF

my $no_hyphens = <<'EOF';
#title Pallino
#author pinco
#lang ru

Этот принцип абсолюта» противоположен принципу, признаваемому
идеалистами всех школ. В то время как последние выводят всю историю —
включая проявление материальных интересов и различных ступеней
экономической организации общества — из проявления идей, немецкие
коммунисты, напротив, во всей человеческой истории, в самых идеальных
проявлениях как коллективной, так и индивидуальной жизни человечества,
во всех интеллектуальных, моральных, религиозных, метафизических,
научных, художественных, политических, юридических и социальных
проявлениях, имевших место в прошлом и происходящих в настоящем,
видели лишь отражение или неизбежный рикошет проявления экономических
фактов. В то время как идеалисты утверждают, что идеи господствуют над
фактами и производят их, коммунисты, наоборот, в полном согласии с
научным материализмом утверждают, что факты порождают идеи и что
последние всегда лишь суть идеальное отражение совершившихся фактов,
что из всех фактов факты экономические, материальные, факты по
преимуществу представляют собой настоящую базу, главное основание;
всякие же другие факты — интеллектуальные и моральные, политические и
социальные — суть лишь необходимо производные.¶

EOF

my $text;

{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($with_hyphens);
    $rev->commit_version;
    $rev->publish_text;
    $text = $rev->title;
}
# now, we have to crash into the git directly, because lately we
# remove the soft hyphens unconditionally, so they can only be old
# texts.

path($text->f_full_path_name)->spew_utf8($with_hyphens);

my $rev = $text->new_revision;
$rev->edit($no_hyphens);
$rev->commit_version;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
my $diff = '/action/text/edit/' . $text->uri . '/' . $rev->id . '/diff';
diag $diff;
$mech->get_ok($diff);
$with_hyphens =~ s/([\x{ad}\x{a0}])/sprintf('&lt;U+%04X&gt;', ord($1))/ge;
$mech->content_contains($with_hyphens);
$mech->content_contains($no_hyphens);
