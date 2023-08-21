#!perl

# web page: splash page
# formats + attachments: constituents

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};

use Data::Dumper;
use Test::More;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::OAI::ORE;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0ore0';

my $site = $schema->resultset('Site')->find($site_id);

unless ($site) {
$site = create_site($schema, $site_id);
$site->update({ pdf => 1, a4_pdf => 1 });
$site->check_and_update_custom_formats;

{
    my $muse = path($site->repo_root, qw/t tt to-test.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#author My author
#title Test me
#authors One <author>; and & anotherrxx
#source From "the" internet
#rights No <copycat>
#topics One topic; And <another>; xAnd&another;
#lang it
#attach shot.pdf
#publisher <testing> publisher
#date 1923 and something else
#subtitle This is a subtitle
#teaser This is the teaser

> Tirsi morir volea,
> Gl'occhi mirando di colei ch'adora;
> Quand'ella, che di lui non meno ardea,
> Gli disse: "Ahimè, ben mio,
> Deh, non morir ancora,
> Che teco bramo di morir anch'io."
>
> Frenò Tirsi il desio,
> Ch'ebbe di pur sua vit'allor finire;
> Ma (E) sentea morte,in (e) non poter morire.
> E mentr'il guardo suo fisso tenea
> Ne' begl'occhi divini
> E'l nettare amoroso indi bevea,
>
> La bella Ninfa sua, che già vicini
> Sentea i messi d'Amore,
> Disse, con occhi languidi e tremanti:
> "Mori, cor mio, ch'io moro."
> Cui rispose il Pastore:
> "Ed io, mia vita, moro."
>
> Cosi moriro i fortunati amanti
> Di morte si soave e si gradita,
> Che per anco morir tornaro in vita.

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

diag "Updating DB from tree";
$site->update_db_from_tree;
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}
if (my $att = $site->attachments->find({ uri => 't-t-1.png' })) {
    $att->edit(
               title_muse => $att->uri . " *title*",
               comment_muse => $att->uri . " *comment*",
               alt_text => $att->uri . " description ",
              );
}

}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


$mech->get_ok('/library/to-test');
$mech->content_contains('/library/to-test/ore.rdf') or diag $mech->content;
$mech->get_ok('/library/to-test/ore.rdf');
is $mech->content_type, 'application/rdf+xml', "Content type is fine";
diag $mech->content;


done_testing;
