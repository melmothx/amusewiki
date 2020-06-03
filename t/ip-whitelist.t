#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 15;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;

use File::Spec::Functions qw/catfile catdir/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::PSGI;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, "0whitelist0");
my $app = AmuseWikiFarm->apply_default_middlewares(AmuseWikiFarm->psgi_app);
my $mech = Test::WWW::Mechanize::PSGI->new(app => $app,
                                           env => {
                                                   REMOTE_ADDR => '66.66.66.66',
                                                   HTTP_HOST => $site->canonical,
                                                  },
                                          );
foreach my $path ('/', '/mirror/index.html', '/git') {
    $site->whitelist_ips->delete;
    $site->update({ mode => 'blog' });
    ok !$site->is_private;

    $mech->get_ok('/');

    $site->update({ mode => 'private' });
    ok $site->is_private;


    $mech->get('/');
    is $mech->status, 401;

    $site->add_to_whitelist_ips({ ip => '66.66.66.66' });
    $mech->get_ok('/');
}
