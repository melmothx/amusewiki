#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 19;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0admins0');

# if root has not visited the form, these will be undef and prevent
# the update. Unclear if bug or feature. Both?

$site->update({
               ssl_key => '',
               ssl_cert => '',
               ssl_ca_cert => '',
               ssl_chained_cert => '',
               logo => '',
              });

use Test::WWW::Mechanize::Catalyst;

# TODO: remove the host, this should be accessible anywhere
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/user/site');
is ($mech->uri->path, '/login', "Bounced to login");
$schema->resultset('User')->search({ username => 'myadmin' })->delete;
my $user = $schema->resultset('User')->create({ username => 'myadmin', password => 'maypass',
                                                user_roles => [ { role => { role => 'librarian' } } ] });
$site->add_to_users($user);
logout_and_login();
diag $mech->uri->path;
$mech->get_ok('/user/create');
is $mech->uri->path, '/user/create';
$mech->get('/user/site');
is $mech->status, '403';
$user->add_to_roles({ role => 'admin' });
logout_and_login();
$mech->get_ok('/user/site');
is $mech->uri->path, '/user/site';
$mech->submit_form(with_fields => {
                                   magic_question => 'Guess what',
                                   magic_answer => '???',
                                  });
$site->discard_changes;
isnt ($site->magic_answer, '???');
isnt ($site->magic_question, 'Guess what');
isnt ($site->canonical, 'garbage');
diag $mech->uri->path;

# no button

$mech->post($mech->uri->as_string, {
                                    canonical => 'garbage',
                                    magic_question => 'Guess what',
                                    magic_answer => '???',
                                    edit_site => 'update',
                                   });
$site->discard_changes;

isnt ($site->magic_answer, '???');
isnt ($site->magic_question, 'Guess what');
isnt ($site->canonical, 'garbage');
diag $mech->uri->path;
$mech->submit_form(with_fields => {
                                   magic_question => 'Guess what',
                                   magic_answer => '???',
                                  },
                   button => 'edit_site');
$site->discard_changes;
is ($site->magic_answer, '???', "Site updated");
is ($site->magic_question, 'Guess what', "Site updated");


sub logout_and_login {
    $mech->get_ok('/logout');
    $mech->get_ok('/login');
    $mech->submit_form(form_id => 'login-form',
                       fields => { username => 'myadmin',
                                   password => 'maypass',
                                 },
                       button => 'submit');
}

