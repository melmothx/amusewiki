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

my $user = $site->users->update_or_create({
                                           username => 'pinco',
                                           password => 'pallino',
                                           active   => 1,
                                          });

$user->set_roles([{ role => 'librarian' }]);

$mech->get_ok( '/login'  );
$mech->get_ok( '/logout' );

$mech->get_ok( '/special/index', "Can access the index page");

$mech->content_lacks('textarea', "No textarea found in special");

$mech->post('/special/index/edit', {
                                    body => "#title blabla\n\nnblablabla\n"
                                   });

like ($mech->uri, qr{/login}, "Bounced to login");

$mech->content_lacks('/special/index', 'blablabla', "Index not updated");

$mech->post('/login' => {
                         username => 'pallino'
                        });

like $mech->uri, qr{/login}, "No authorized, still on login";

$mech->post('/login' => {
                         username => 'pinco',
                         password => 'pallino'
                        });

$mech->content_contains(q{/logout"}, "Page contains the logout link");
$mech->get_ok( '/logout' );

done_testing();
