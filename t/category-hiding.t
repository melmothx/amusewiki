#!perl

use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 7;
use File::Spec::Functions qw/catfile catdir/;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cathiding';
my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

ok $site->is_without_authors;
ok $site->is_without_topics;

my ($revision) = $site->create_new_text({ uri => 'the-text',
                                          title => 'Hello',
                                          lang => 'hr',
                                          textbody => '',
                                        }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n#lang en\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
my $uri = $revision->publish_text;
ok $uri, "Found uri $uri";

# caching
ok $site->is_without_authors;
ok $site->is_without_topics;

$site = $site->get_from_storage;
ok !$site->is_without_authors;
ok !$site->is_without_topics;

