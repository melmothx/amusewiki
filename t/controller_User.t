use strict;
use warnings;
use Test::More;


unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');


my $schema = AmuseWikiFarm::Schema->connect('amuse');

# insert a bogus user

my $site = $schema->resultset('Site')->find('0blog0');

is $site->mode, 'modwiki', "Site mode is blog";

my $user = $site->users->update_or_create({
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
$mech->get('/action/special/edit/index');

is $mech->response->base->path, '/human', "Bounced to login page";

$mech->get('/special/pippo/edit');

is $mech->response->base->path, '/human', "Bounced to login";

$mech->content_contains("Please prove you are a human");

$mech->post('/login' => {
                         username => 'pallino'
                        });

is $mech->response->base->path, '/login', "No authorized, still on login";

$mech->post('/login' => {
                         username => 'pinco',
                         password => 'pallino',
                         submit => 1,
                        });

$mech->content_contains(q{/logout"}, "Page contains the logout link");

$mech->get_ok('/action/special/edit/index');
$mech->content_contains('textarea');


$mech->get_ok( '/logout' );

like $mech->uri, qr{/login}, "Bounced to login";
like $mech->content, qr{You have logged out}, "status message correct";

done_testing();
