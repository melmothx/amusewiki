#!/perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 3;
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

my $site = create_site($schema, '0crashloc0');

my ($rev) = $site->create_new_text({ uri => 'crashy', title => 'Crash' }, 'text');
$rev->edit("#topics my stuff [asdf]\n" . $rev->muse_body);
$rev->commit_version;
my $uri = $rev->publish_text;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/library/crashy');
$mech->get_ok('/category/topic');
$mech->get_ok('/category/topic/my-stuff-asdf');
