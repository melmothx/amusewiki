#!perl

use strict;
use warnings;

use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0user3';
my $site = create_site($schema, $site_id);
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$site->update({
               mode => 'modwiki',
               magic_question => 'x',
               magic_answer => 'x',
              });

$mech->get_ok('/');
$mech->get_ok('/bookbuilder');
is ($mech->uri->path, '/human');
$mech->submit_form(with_fields => {
                                   answer => 'x',
                                  },
                   button => 'submit');
is ($mech->uri->path, '/bookbuilder');

# then test the editing

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");


$mech->get_ok('/action/text/new');
is ($mech->uri->path, '/human');
$mech->submit_form(with_fields => {
                                   answer => 'x',
                                  },
                   button => 'submit');
is ($mech->uri->path, '/action/text/new');

$mech->get_ok('/action/special/new');
is ($mech->uri->path, '/login');
$mech->submit_form(with_fields => {
                                   username => 'root',
                                   password => 'root',
                                  },
                   button => 'submit');
is ($mech->uri->path, '/action/special/new');
