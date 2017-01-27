#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 30;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0cformats0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get('/settings/formats');
is $mech->status, '401';
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';

