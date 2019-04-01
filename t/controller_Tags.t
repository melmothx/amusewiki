#!perl
use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Test::More tests => 19;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0tags0');

{
    my $parent;
    foreach my $uri (qw/one two three four five six seven eight/) {
        my $tag = $site->tags->create({ uri => $uri });
        if ($parent) {
            $tag->parent_tag($parent);
            $tag->update;
        }
        $parent = $tag;
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


is $site->tags->find({ uri => 'six' })->full_uri, 'tags/one/two/three/four/five/six';
is $site->tags->find({ uri => 'one' })->full_uri, 'tags/one';

foreach my $tag ($site->tags) {
    my @ancestors = $tag->ancestors;
    if ($tag->uri eq 'one') {
        ok !scalar(@ancestors), "Root node";
        ok $tag->is_root;
    }
    else {
        ok scalar(@ancestors), "Found ancestors";
    }
    diag $tag->full_uri;
    $mech->get_ok($tag->full_uri);
}

