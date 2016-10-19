#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 28;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0admins0');

use Test::WWW::Mechanize::Catalyst;

# TODO: remove the host, this should be accessible anywhere
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/'); # warm up
$mech->get('/user/site');
is ($mech->status, 401, "Bounced to login");
$schema->resultset('User')->search({ username => 'myadmin' })->delete;
my $user = $schema->resultset('User')->create({ username => 'myadmin', password => 'maypass',
                                                user_roles => [ { role => { role => 'librarian' } } ] });
$site->add_to_users($user);
logout_and_login();
diag $mech->uri->path;
$mech->get_ok('/user/create');
is $mech->uri->path, '/user/create';
$mech->get('/user/site');
is $mech->status, '403', "status for " . $mech->uri . " is 403 (permission denied)";
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
                                   pagination_size => 24,
                                   pagination_size_latest => 25,
                                   pagination_size_search => 26,
                                   pagination_size_monthly => 27,
                                   pagination_size_category => 28,
                                  },
                   button => 'edit_site');
$site = $schema->resultset('Site')->find($site->id);
is ($site->magic_answer, '???', "Site updated");
is ($site->magic_question, 'Guess what', "Site updated");
is ($site->pagination_size, 24, "pagination latest ok");
is ($site->pagination_size_latest, 25, "pagination latest ok");
is ($site->pagination_size_search, 26, "pagination search ok");
is ($site->pagination_size_monthly, 27, "pagination monthly ok");
is ($site->pagination_size_category, 28, "pagination category ok");


my $other = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                max_redirect => 0,
                                                host => 'blog.amusewiki.org');

$other->get_ok('/library');
$other->get('/user/site');
is $other->status, 401;
$other->submit_form(with_fields => { __auth_user => 'myadmin',
                                     __auth_pass => 'maypass',
                                   });
is $other->uri->path, '/user/site';
is $other->status, 401, "admin can't login on other sites";


sub logout_and_login {
    $mech->get_ok('/logout');
    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => 'myadmin',
                                        __auth_pass => 'maypass',
                                 });
}

