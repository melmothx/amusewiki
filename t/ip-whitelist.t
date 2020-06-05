#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 30;

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
