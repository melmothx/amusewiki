#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 63;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;

use File::Spec::Functions qw/catfile catdir/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::PSGI;
use AmuseWikiFarm::Archive::StaticIndexes;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, "0whitelist0");
my $app = AmuseWikiFarm->apply_default_middlewares(AmuseWikiFarm->psgi_app);
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app,
                                           env => {
                                                   REMOTE_ADDR => '66.66.66.66',
                                                   HTTP_HOST => $site->canonical,
                                                  },
                                          );
$site->update({ cgit_integration => 0 });
$site->site_options->update_or_create({ option_name => 'restrict_mirror', option_value => 1 });
AmuseWikiFarm::Archive::StaticIndexes->new(site => $site)->generate;


foreach my $path ('/', '/mirror/index.html', '/git') {
    $site->whitelist_ips->delete;
    $site->update({ mode => 'blog' });
    ok !$site->is_private;

    $mech->get($path);
    my $status = $mech->status;
    if ($path eq '/') {
        is $status, 200;
    }
    else {
        is $status, 401; # because of the settings.
    }
    $site->update({ mode => 'private' });
    ok $site->is_private;


    $mech->get($path);
    is $mech->status, 401;

    $site->add_to_whitelist_ips({ ip => '66.66.66.66' });
    $mech->get_ok($path);
    $mech->get('/login');
    is $mech->uri->path, '/login', "whitelisting doesn't interfere with login";
    $mech->get('/user/site');
    is $mech->status, 401, "Can't access reserved parts despite whitelist";
    $mech->get('/admin/sites');
    is $mech->status, 401, "Can't access reserved parts despite whitelist";
}


my $other = Test::WWW::Mechanize::PSGI->new(app => $app,
                                            env => {
                                                    REMOTE_ADDR => '66.66.66.67',
                                                    HTTP_HOST => $site->canonical,
                                                   },
                                           );

foreach my $path ('/', '/mirror/index.html', '/git') {
    $mech->get_ok($path);
    $other->get($path);
    is $other->status, 401;
}

my $user = $schema->resultset('User')->find({ username => 'root' });
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

$mech->get_ok('/admin/sites/edit/' . $site->id);
$mech->content_lacks('66.66.66.66', "root ip not displayed");
$mech->submit_form(with_fields => { whitelist_ips => "\n66.12.23.23\n\n111.111.111" },
                   button => 'edit_site');

# including the first one, which is from the CLI
is $site->get_from_storage->whitelist_ips->count, 3;

$site->whitelist_ips->update({ user_editable => 1 });

$mech->get_ok("/authorize-ip/" . $user->get_api_access_token);

$mech->get_ok('/admin/sites/edit/' . $site->id);
$mech->content_contains('66.66.66.66', "ip displayed");
$mech->submit_form(with_fields => { whitelist_ips => "\n66.12.23.23\n\n111.111.111" },
                   button => 'edit_site');

is $site->get_from_storage->whitelist_ips->count, 2;

$mech->get_ok("/authorize-ip/" . $user->get_api_access_token);

is $site->get_from_storage->whitelist_ips->count, 3;

$site->whitelist_ips->search({ ip => '66.66.66.66' })->delete;

# check git

{
    $mech->get('/logout');
    $site->update({
                   mode => 'blog',
                   cgit_integration => 0,
                  });
    $mech->get_ok('/', "Can access the home page");
    $mech->get('/git');
    is $mech->status, 401, "Cannot access /git";
    $mech->get('/mirror');
    is $mech->status, 401, "Cannot access /mirror";
    $site->add_to_whitelist_ips({ ip => '66.66.66.66' });
    $mech->get('/git');
    is $mech->status, 200, "Can access /git";
    $mech->get('/mirror');
    is $mech->status, 200, "Can access /mirror";
}

$site->whitelist_ips->delete;

{
    my $token = $user->get_api_access_token({ reset => 1 });
    $mech->get('/git');
    is $mech->status, 401, "Cannot access /git";
    $mech->get('/mirror');
    is $mech->status, 401, "Cannot access /mirror";
    $mech->get("/authorize-ip/x$token");
    is $mech->status, 403;
    $mech->get("/authorize-ip/x");
    is $mech->status, 403;
    $mech->get_ok("/authorize-ip/$token");
    $mech->get_ok("/authorize-ip/$token");
    diag $mech->content;
    $mech->get_ok('/git');
    $mech->get_ok('/mirror');
    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
    $mech->get_ok('/console/git');
    $mech->content_contains($token);
    $mech->get_ok('/refresh-api-access-token');
    $mech->content_lacks($token);
    isnt $user->discard_changes->get_api_access_token, $token;
    $token = $user->discard_changes->get_api_access_token;
    $mech->get_ok('/admin/sites/edit/' . $site->id);
    $mech->content_lacks('66.66.66.66', "Temporary auth not displayed");

    $mech->get('/logout');
    $mech->get('/git');
    is $mech->status, 401;
    $mech->get_ok("/authorize-ip/$token");
    $mech->get_ok('/git');

    $mech->get_ok('/git');
    $site->whitelist_ips->search({ expire_epoch => { '>' => 0 } })->update({ expire_epoch => 10 });
    $mech->get('/git');
    is $mech->status, 401;
}
