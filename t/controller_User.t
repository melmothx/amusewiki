use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 88;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $site_id = '0user0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $other_site_id = '0other0';
my $other_site = create_site($schema, $other_site_id);

my $othermech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    host => "$other_site_id.amusewiki.org");

my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

my ($rev) = $site->create_new_text({ uri => 'index',
                                     title => 'test',
                                     textbody => 'Hello' }, 'special');

my $index_text_id = $rev->title->id;
ok($index_text_id, "Id for index is $index_text_id");

$site->mode('blog');
$site->update;

ok($rev);
$rev->commit_version;
$rev->publish_text;

$schema->resultset('User')->search({username => [qw/pinco pincuz/] })->delete;

my $user = $site->update_or_create_user({
                                         username => 'pinco',
                                         password => 'pallino',
                                         active   => 1,
                                        });

$user->set_roles([{ role => 'librarian' }]);

$mech->get_ok( '/login'  );
$mech->get_ok( '/logout' );
$mech->get_ok( '/human'  );
$mech->get_ok( '/special/index', "Can access the index page");

$mech->content_lacks('textarea', "No textarea found in special");

$mech->content_lacks('/admin/', "No link to admin");
$mech->content_lacks('/action/special/edit/index', "No link to admin");

$mech->get('/special/index/edit');

is $mech->response->base->path, '/action/special/edit/index';
is $mech->status, 403;

ok(!$schema->resultset('Revision')->search({
                                            site_id => '0user0',
                                            status => 'editing',
                                            title_id => $index_text_id,
                                           })->count,
   "No index revision (1)");

$mech->get('/special/pippo/edit');

ok(!$schema->resultset('Revision')->search({
                                            site_id => '0user0',
                                            status => 'editing',
                                            title_id => $index_text_id,
                                           })->count,
   "No index revisions (2)") or diag $mech->content;
is $mech->status, '404';

$mech->get('/login');
$mech->submit_form(with_fields => { __auth_user => 'pallino' });
is $mech->response->base->path, '/login', "No authorized, still on login";

ok(!$schema->resultset('Revision')->search({
                                            site_id => '0user0',
                                            status => 'editing'
                                           })->count,
   "No index revisions(2a)");


$mech->submit_form(with_fields => { __auth_user => 'pinco', __auth_pass => 'pallino' });
$mech->content_contains(q{/logout"}, "Page contains the logout link");
diag $mech->uri;


ok(!$schema->resultset('Revision')->search({
                                            site_id => '0user0',
                                            status => 'editing'
                                           })->count,
   "No index revisions(2b)");


$mech->get_ok('/logout');


my $user_active = $schema->resultset('User')->find({ username => 'pinco' });
ok($user_active);
$user_active->active(0);
$user_active->update;

$mech->get_ok('/login');
$mech->content_contains('login-form');

$mech->submit_form(with_fields => { __auth_user => 'pinco', __auth_pass => 'pallino' });
is $mech->response->base->path, '/login',
  "No authorized, still on login because not active";
$mech->content_contains('login-form');

ok(!$schema->resultset('Revision')->search({
                                            site_id => '0user0',
                                            status => 'editing'
                                           })->count,
   "No index revisions(3)");

$mech->get('/action/special/edit/index');
is $mech->status, 403;

$mech->content_lacks('textarea', "No textarea found for not logged-in");

$user_active->active(1);
$user_active->update;

$mech->get_ok('/login');
$mech->content_contains('login-form');
$mech->submit_form(with_fields => { __auth_user => 'pinco', __auth_pass => 'pallino' });
$mech->content_contains(q{/logout"}, "Page contains the logout link");

$othermech->get_ok('/login');
$othermech->content_contains('name="__auth_pass"');
$othermech->content_contains('name="__auth_user"');
$othermech->submit_form(with_fields => { __auth_user => 'pinco', __auth_pass => 'pallino' });
$othermech->content_contains('Wrong username or password',
                             "Can't login in other site");

$mech->get_ok('/action/special/edit/index');
$mech->content_contains('textarea');

$mech->get_ok('/action/text/edit/indexxxxxx');

ok($mech->form_with_fields(qw/title subtitle date/),
   "Landed on the /action/text/new");

is $mech->uri->path, '/action/text/new';


$mech->get_ok( '/logout' );
like $mech->content, qr{You have logged out}, "status message correct";

$mech->get('/user/create');
is $mech->status, 403;
$mech->content_contains('__auth_user');
$mech->content_lacks('__auth_human');

# let pinco create a new fellow librarian

my @users = $site->users;

is (scalar(@users), 1, "Found 1 user");

$mech->submit_form(with_fields => { __auth_user => 'pinco', __auth_pass => 'pallino' });

$mech->content_contains('You are logged in') or diag $mech->content;

$mech->get_ok('/user/create');

$mech->submit_form(with_fields => {
                                   username => 'pinco',
                                   password => 'pallinopinco',
                                   passwordrepeat => 'pallinopinco',
                                   email => 'pinco@amusewiki.org',
                                   emailrepeat => 'pinco@amusewiki.org',
                                  },
                   button => 'create');


$mech->content_contains('already exists') or diag $mech->content;

# check validation

my $form = goodform();
$form->{password} = '123';
$form->{passwordrepeat} = '123';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Password too short');

$form = goodform();
$form->{passwordrepeat} = 'xx';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Passwords do not match');

$form = goodform();
$form->{emailrepeat} = 'xx';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Emails do not match');


$form = goodform();
$form->{email} = $form->{emailrepeat} = 'xx@xx';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Invalid email');


$form = goodform();
$form->{username} = "_pippo_";
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Invalid username');

$form = goodform();
$form->{password} = $form->{passwordrepeat} = '1234';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Password too short');

$form = goodform();
delete $form->{passwordrepeat};
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Some fields are missing');

$form = goodform();
$form->{username} = 'pinco';
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Such username already exists');

$form = goodform();
$form->{username} = 'root'; # root is create in 00-prepare-tests
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('Such username already exists');

ok(!$site->users->find({ username => 'root' }), "But no root on the site");

$form = goodform();
$mech->submit_form(with_fields => $form,
                   button => 'create');
$mech->content_contains('User pincuz created!') or diag $mech->content;

@users = $site->users;

is (scalar(@users), 2, "Now the site has two users");

my $pincuz = $site->users->find({ username => 'pincuz' });
is $pincuz->created_by, 'pinco', "user pincuz was created by pinco";

is $pincuz->email, $form->{email}, "Mail ok";

ok $pincuz->check_password($form->{password}), "password ok";

ok $pincuz->active, "active ok";

is $pincuz->roles->first->role, 'librarian', "Found role librarian";


$mech->get_ok( '/logout' );
like $mech->content, qr{You have logged out}, "status message correct";
$mech->get_ok('/login');
$mech->content_contains('__auth_user');
$mech->content_lacks('__auth_human');


# now, pincuz log in and updates its info

$mech->submit_form(with_fields =>  {
                                    __auth_user => $pincuz->username,
                                    __auth_pass => $form->{password},
                                   });

$mech->content_contains('You are logged in') or diag $mech->content;

my $userid = $pincuz->id;

die "Test are broken" if $userid < 4;

foreach my $i (1..3) {
    $mech->get("/user/edit/$i");
    is $mech->status, "403", "librarian can't access other editing";
}

$mech->get('/');

$mech->follow_link(text_regex => qr/Update account info/);

is ($mech->uri->path, '/user/edit/' . $pincuz->id,
    "Landed on " . $mech->uri->path);

{
    my $edit_path = $mech->uri->path;
    $mech->get_ok( '/logout' );
    $mech->get($edit_path);
    is $mech->status, 403;
    $mech->submit_form(with_fields =>  {
                                        __auth_user => $pincuz->username,
                                        __auth_pass => $form->{password},
                                       });
    is $mech->uri->path, $edit_path;
}

$mech->submit_form(button => 'update',
                   with_fields => {
                                   password => 'pippo',
                                   passwordrepeat => 'pippo',
                                   email => 'xxx',
                                   emailrepeat => 'xxx',
                                  });

$mech->content_lacks("Password updated");
$mech->content_contains("Password too short");
$mech->content_contains("Invalid email");

$mech->submit_form(button => 'update',
                   with_fields => {
                                   password => 'pippox',
                                   passwordrepeat => 'pippo',
                                   email => 'xxxx',
                                   emailrepeat => 'xxx',
                                  });

$mech->content_lacks("Password updated");
$mech->content_contains("Passwords do not match");
$mech->content_contains("Emails do not match");

my $newpassword = 'pippoxxxxx';
my $newemail = 'pipppppo@amusewiki.org';

$mech->submit_form(button => 'update',
                   with_fields => {
                                   password => $newpassword,
                                   passwordrepeat => $newpassword,
                                   email => $newemail,
                                   emailrepeat => $newemail,
                                  });

$mech->content_contains("Password updated");
$mech->content_contains("Email updated");

$pincuz->discard_changes;
is ($pincuz->email, $newemail, "Email correctly changed");
ok ($pincuz->check_password($newpassword), "Password correctly changed");


diag "Purging users";

$site->users->delete;

sub goodform {
    return {
            username => 'pincuz',
            password => 'pallinopinco',
            passwordrepeat => 'pallinopinco',
            email => 'pinco@amusewiki.org',
            emailrepeat => 'pinco@amusewiki.org',
           };
}
