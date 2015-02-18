#!perl
use utf8;
use strict;
use warnings;
use Test::More tests => 27;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

# TODO: remove the host, this should be accessible anywhere
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $new_username = 'piccoloutente';

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
    is ($mech->status, 403);
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

$mech->get_ok('/admin/users');

my $userobj = $schema->resultset('User')->find({ username => $new_username });

ok ($userobj, "$new_username created and found: " . $userobj->id);

$mech->submit_form(form_id => 'delete-user-form-' . $userobj->id,
                   button => 'delete');

diag $mech->uri->path;
$mech->content_contains('id="status_message">');
ok (!$schema->resultset('User')->find({ username => $new_username }),
    "$new_username deleted");

foreach my $id (qw/garbage 9999999999/) {
    foreach my $path ("/admin/users/$id",
                      "/admin/users/$id/delete",
                      "/admin/users/$id/edit") {
        $mech->get($path);
        is ($mech->status, 404, "$path is 404");
    }
}

