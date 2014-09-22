#!perl

use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 8;

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;


my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0canonicals0';

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get('/');
is $mech->status, '403', "Access forbidded against non-existent host";

my $site = create_site($schema, $site_id);
$mech->get_ok('/', "After site creation, site can be accessed");

$site->update({ canonical => 'blablabla.amusewiki.org' });
$mech->get('/');
is $mech->status, '403', "Access forbidded after canonical change";

# then add the original host to the vhost

$site->add_to_vhosts({ name => $site_id . '.amusewiki.org' });
$mech->get_ok('/', "With hostname in vhost, site can be accessed again");

is_deeply [ $site->all_site_hostnames ],
  [ "blablabla.amusewiki.org", "$site_id.amusewiki.org" ],
  "Checked all_site_hostnames";

is_deeply [ $site->alternate_hostnames ],
  [ "$site_id.amusewiki.org" ], "alternate_hostnames ok";

$site->update({ secure_site => 0 });

is $site->canonical_url, 'http://blablabla.amusewiki.org', "Url ok";

$site->update({ secure_site => 1 });

is $site->canonical_url, 'https://blablabla.amusewiki.org', "Url ok with https";


$site->delete;
