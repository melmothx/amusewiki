#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 54;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $one = create_site($schema, "0uadminone0");
my $two = create_site($schema, "0uadmintwo0");

my $mechroot = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $one->canonical);

my $mechone = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                  host => $one->canonical);

my $mechtwo = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                  host => $two->canonical);

my $pass = 'pizzapizza888';

$mechone->get_ok('/');
$mechtwo->get_ok('/');
$mechroot->get_ok('/');

$mechroot->get_ok('/login');
$mechroot->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mechroot->content_contains('/admin/users');
$mechroot->content_lacks('/site-admin/users');
$mechroot->get_ok('/admin/users');

$schema->resultset('User')->search({ username => { -like => "ad0%" } })->delete;

# root will create the admin users
foreach my $site_id ($one->id, $two->id) {
    $mechroot->submit_form(form_id => 'user-create-form',
                           fields => { username => "ad" . $site_id },
                           button => 'create'
                          );
    $mechroot->submit_form(with_fields => {
                                           email => $site_id . '@amusewiki.org',
                                           password => $pass,
                                           passwordrepeat => $pass,
                                           active => 1,
                                           'site-' . $site_id => 1,
                                           'role-librarian' => 1,
                                           'role-admin' => 1,
                                          },
                           button => 'update');
}

# check if they can login now and access the user page
foreach my $m ([$one, $mechone], [$two, $mechtwo]) {
    my ($site, $mech) = @$m;
    $mech->get_ok('/login');
    my $user = $site->users->find({ username => "ad" . $site->id });
    ok $user;
    ok $user->email;
    diag $user->email;
    $mech->submit_form(with_fields => { __auth_user => $user->username, __auth_pass => $pass });
    $mech->content_contains('/site-admin/users');
    $mech->content_lacks('/admin/users');
    $mech->get('/admin/users');
    is $mech->status, 403;
    $mech->get_ok('/site-admin/users?bare=1');
    diag $mech->content;
    $mech->content_contains($user->email);
    $mech->content_lacks('fa-trash');
    # trying to delete myself:
    $mech->post('/site-admin/users/delete/' . $user->id, {
                                                          delete => 1,
                                                         });
    $mech->content_contains("This user cannot be removed");
    $mech->content_contains($user->email, "User was not deleted");
    # trying to delete root;
    my $root = $schema->resultset('User')->find({ username => 'root' });
    $mech->post('/site-admin/users/delete/' . $root->id, {
                                                          delete => 1,
                                                         });
    ok $schema->resultset('User')->find({ username => 'root' }), "Root was not deleted";
    $mech->content_contains("This user cannot be removed");
}

# now let's add some librarians to both the sites.
# the deletion buttons should pop up. But deleting 

my @librarians;
foreach my $username (qw/uno due tre quattro/) {
    my $user = $schema->resultset('User')->create({
                                                   username => "ad0" . $username,
                                                   password => $username,
                                                   user_roles => [ { role => { role => 'librarian' } } ],
                                                  });
    push @librarians, $user;
    foreach my $site ($one, $two) {
        $site->add_to_users($user);
    }
}

foreach my $m ([$one, $mechone], [$two, $mechtwo]) {
    my ($site, $mech) = @$m;
    $mech->get_ok('/site-admin/users?bare=1');
    diag $mech->content;
    foreach my $u (@librarians) {
        $mech->content_contains($u->username);
    }
    $mech->content_contains('amusewiki.org/site-admin/users/delete/');
}

# now delete from site one. On site two they should still be present

DELETION: {
    $mechone->get_ok('/site-admin/users');
    foreach my $user (@librarians) {
        $mechone->submit_form(form_id => "delete-user-form-" . $user->id,
                              button => 'delete');
        $mechone->content_lacks("delete-user-form-" . $user->id) or diag $mechone->content;
        $mechtwo->get('/site-admin/users?bare=1');
        $mechtwo->content_contains("delete-user-form-" . $user->id) or diag $mechtwo->content;
    }
}
