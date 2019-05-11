#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 9;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse qw/to_json/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0loc0');

# so we can test againt "Host virtuali"
my $cat = 'Virtual hosts';
my $it = "Host virtuali";
my $xcat = 'Texst';
my $xit = 'Prova';

path($site->lexicon_file)->spew_raw(to_json({ Texst => { it => 'Prova' } }));

{
    my ($rev) = $site->create_new_text({ title => 'another-text',
                                         lang => 'en',
                                         SORTtopics => "$cat; Texst",
                                         textbody => 'ciao',
                                       }, 'text');
    $rev->commit_version;
    $rev->publish_text;
}

$site->update_db_from_tree(sub { diag @_ });
$site->generate_static_indexes(sub { diag @_ });
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/?__language=it');
$mech->get_ok('/library/another-text');
$mech->content_contains('Argomenti');
$mech->get_ok('/category/topic/virtual-hosts');
$mech->content_contains($cat);
$mech->content_lacks($it);
$mech->get_ok('/category/topic/texst');
$mech->content_contains($xit);
$mech->content_lacks($xcat);
