#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0paging0');

$site->update({
               ssl_key => '',
               ssl_cert => '',
               ssl_ca_cert => '',
               ssl_chained_cert => '',
               logo => '',
              });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my ($user, $pass) = (qw/pagadim pagpass/);
$schema->resultset('User')->search({ username => $user })->delete;
$schema->resultset('User')->create({ username => $user,
                                     password => $pass,
                                     user_roles => [ { role => { role => 'admin' } } ] });

$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => $user,
                               password => $pass,
                             },
                   button => 'submit');
$mech->get_ok('/user/site');


