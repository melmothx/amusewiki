#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use utf8;
use strict;
use warnings;
use Test::More tests => 58;
use Data::Dumper;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

# TODO: remove the host, this should be accessible anywhere
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $new_username = 'piccoloutente';
my $new_password = 'nuovapass';

ok ($schema);

# cleanup

if (my $user = $schema->resultset('User')->find({ username => $new_username })) {
    $user->delete;
}


# TODO: provide a login path for root users
foreach my $path ('/admin/users',
                  '/admin/users/1',
                  '/admin/users/1/delete',
                  '/admin/users/1/edit') {
    $mech->get($path);
    is ($mech->uri->path, '/login');
}
$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');
$mech->get_ok('/admin/users');

foreach my $bad_username ('root', '1', 'abc' x 250,
                          'asdf asdf', 'à à c',
                          '{x}') {
    $mech->submit_form(form_id => 'user-create-form',
                       fields => { username => $bad_username },
                       button => 'create');
    $mech->content_contains('error_message', "$bad_username not allowed");
    
}

$mech->submit_form(form_id => 'user-create-form',
                   fields => { username => '1' },
                   button => 'create');

$mech->content_contains('error_message');

$mech->submit_form(form_id => 'user-create-form',
                   fields => { username => $new_username },
                   button => 'create');

$mech->content_lacks('error_message');
my $edit_url = $mech->uri->path;
like $edit_url, qr{^/admin/users/\d+$};
$mech->get_ok($edit_url);

diag "Editing $new_username";
my $userobj = $schema->resultset('User')->find({ username => $new_username });
ok ($userobj, "$new_username created and found: " . $userobj->id);
is $userobj->created_by, 'root', "user created by root";

my $default_pass = $userobj->password->hash_hex;
ok(!$userobj->active, "User is inactive");

$mech->submit_form(with_fields => {
                                   email => 'info@amusewiki.org',
                                   password => $new_password,
                                   passwordrepeat => $new_password,
                                   active => 1,
                                   'site-0blog0' => 1,
                                   'role-librarian' => 1,
                                  },
                   button => 'update');
$userobj->discard_changes;
is $userobj->email, 'info@amusewiki.org';
isnt $userobj->password->hash_hex, $default_pass, "Password updated";
ok ($userobj->active, "User now is active");

is_deeply $userobj->role_list, [
                                {
                                 role => 'librarian',
                                 active => 1,
                                },
                                {
                                 role => 'root',
                                 active => undef,
                                }
                               ], "Roles ok"
  or diag Dumper($userobj->role_list);

is $userobj->sites->first->id, '0blog0';
is $userobj->roles->first->role, 'librarian';
is $userobj->sites->count, 1, "Only one site";
is $userobj->roles->count, 1, "One role";
is $mech->uri->path, '/admin/users';


$mech->get_ok('/admin/users');

$mech->content_contains('<span class="user-created-by">root</span>');

foreach my $id (qw/garbage 9999999999/) {
    foreach my $path ("/admin/users/$id",
                      "/admin/users/$id/delete",
                      "/admin/users/$id/edit") {
        $mech->get($path);
        is ($mech->status, 404, "$path is 404");
    }
}

$mech->get_ok('/logout');

foreach my $path ('/admin/users',
                  '/admin/users/1',
                  '/admin/users/1/delete',
                  '/admin/users/1/edit') {
    $mech->get($path);
    is ($mech->uri->path, '/login');
}

# after login with the new user, we should be denied
$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => $new_username,
                               password => $new_password,
                             },
                   button => 'submit');
$mech->content_lacks('login-form');
isnt $mech->uri->path, '/login', "Login appears ok";

foreach my $path ('/admin/users',
                  '/admin/users/1',
                  '/admin/users/1/delete',
                  '/admin/users/1/edit') {
    $mech->get($path);
    is ($mech->status, 403);
}

# logout and and login again with root, delete the user and try to
# login again.

$mech->get_ok('/logout');
$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');
$mech->get_ok('/admin/users');
$mech->submit_form(form_id => 'delete-user-form-' . $userobj->id,
                   button => 'delete');
$mech->content_contains('id="status_message">');
ok (!$schema->resultset('User')->find({ username => $new_username }),
    "$new_username deleted");

$mech->get_ok('/logout');
$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => $new_username,
                               password => $new_password,
                             },
                   button => 'submit');
$mech->content_contains('login-form');
is $mech->uri->path, '/login', "Still at login";
