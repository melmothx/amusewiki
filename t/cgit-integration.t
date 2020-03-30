#!perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 33;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use Digest::SHA;
use Data::Dumper::Concise;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cgit0';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({
               secure_site => 0,
               pdf => 0,
              });
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

{
    my $muse = path($site->repo_root, qw/t tt to-test.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#title Test me
#lang ru
#attach shot.pdf

Все смешалось в доме Облонских. Жена узнала, что муж был в связи с
бывшею в их доме француженкою-гувернанткой, и объявила мужу, что не
может жить с ним в одном доме. Положение это продолжалось уже третий
день и мучительно чувствовалось и самими супругами, и всеми членами
семьи, и домочадцами. Все члены семьи и домочадцы чувствовали, что нет
смысла в их сожительстве и что на каждом постоялом дворе случайно
сошедшиеся люди более связаны между собой, чем они, члены семьи и
домочадцы Облонских. Жена не выходила из своих комнат, мужа третий
день не было дома. Дети бегали по всему дому, как потерянные;
англичанка поссорилась с экономкой и написала записку приятельнице,
прося приискать ей новое место; повар ушел еще вчера со двора, во
время обеда; черная кухарка и кучер просили расчета. 

[[t-t-1.png]]

[[t-t-2.jpeg]]

MUSE

    path(t => files => 'shot.pdf')->copy(path($site->repo_root, 'uploads', 'shot.pdf'));
    path(t => files => 'shot.png')->copy(path($site->repo_root, qw/t tt t-t-1.png/));
    path(t => files => 'shot.jpg')->copy(path($site->repo_root, qw/t tt t-t-2.jpeg/));
    $site->git->add('uploads');
    $site->git->add('t');
    $site->git->commit({ message => "Added files" });
}

$site->update_db_from_tree;


$mech->get_ok('/');
# now we check the encoding
foreach my $url ('/git/0cgit0/tree/t/tt/to-test.muse',
                 '/git/0cgit0/plain/t/tt/to-test.muse',
                 '/git/0cgit0/commit/t/tt/to-test.muse',
                 '/git/0cgit0/diff/t/tt/to-test.muse',
                 '/git/0cgit0/diff',
                 '/git/0cgit0/commit',
                ) {
    $mech->get_ok($url);
    $mech->content_contains('Все смешалось в доме Облонских. Жена узнала, что муж был в');
}
foreach my $f ('t/tt/t-t-2.jpeg', 't/tt/t-t-1.png', 'uploads/shot.pdf') {
    $mech->get_ok('/git/0cgit0/tree/' . $f);
    $mech->get_ok('/git/0cgit0/commit/' . $f);
    $mech->get_ok('/git/0cgit0/plain/' . $f);
    my $res = $mech->response;
    diag Dumper({ $res->headers->flatten });
    ok $res->headers->header('Content-Disposition'), "$f is a download file";
    my $got_sha = Digest::SHA->new('SHA-1')->add($mech->content);
    my $src_sha = Digest::SHA->new('SHA-1')->addfile(path($site->repo_root, $f)->stringify);
    is $got_sha->hexdigest, $src_sha->hexdigest, "$f is fine";
}

$mech->get("/git/0cgit0/tree/asdfasdf");
is $mech->status, 404;
is $mech->content, ('404 Not found');
$mech->get_ok("/git");
$mech->content_contains("https://0cgit0.amusewiki.org/git/0cgit0");
