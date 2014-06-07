use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 21;
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
my $site = create_site($schema, $site_id);


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

my $rev = $site->create_new_text({ uri => 'index',
                                   title => 'test',
                                   textbody => 'Hello' }, 'special');

$site->mode('blog');
$site->update;

ok($rev);
$rev->publish_text;

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

is $mech->response->base->path, '/login', "Bounced to human page";

$mech->get('/action/special/edit/index');

is $mech->response->base->path, '/login', "Bounced to login page";

$mech->get('/special/pippo/edit');

is $mech->response->base->path, '/login', "Bounced to login";

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

$mech->get_ok('/action/text/edit/indexxxxxx');

ok($mech->form_with_fields(qw/title subtitle date/),
   "Landed on the /action/text/new");

is $mech->uri->path, '/action/text/new';


$mech->get_ok( '/logout' );

like $mech->uri, qr{/login}, "Bounced to login";
like $mech->content, qr{You have logged out}, "status message correct";

$user->delete;
