#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 62;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cats0';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({
               secure_site => 0,
               pdf => 0,
              });
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);
$mech->get_ok('/');

foreach my $name (qw/one two three four/) {
    my ($revision) = $site->create_new_text({ uri => "name-$name",
                                              title => "Hello $name",
                                              lang => 'en',
                                              textbody => "Bla bla $name"
                                            }, 'text');
    $revision->edit("#SORTauthors fixed; $name\n#SORTtopics fixed; $name\n" . $revision->muse_body);
    $revision->commit_version;
    my $uri = $revision->publish_text;
    ok $uri, "Found uri $uri";
    $mech->get_ok($uri);
    $mech->content_contains("/topic/$name");
    $mech->content_contains("/topic/fixed");
    $mech->content_contains("/author/$name");
    $mech->content_contains("/author/fixed");

    $mech->get_ok("/category/topic/$name");
    $mech->get_ok("/category/author/$name");

    $site->categories->search({ uri => $name })->update({ active => 0 });
    $mech->get_ok($uri);

    $mech->content_lacks("/topic/$name");
    $mech->content_contains("/topic/fixed");
    $mech->content_lacks("/author/$name");
    $mech->content_contains("/author/fixed");

    $mech->get("/category/topic/$name");
    is $mech->status, 404;
    $mech->get("/category/author/$name");
    is $mech->status, 404;
}

