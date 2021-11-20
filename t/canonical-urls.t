#!perl

use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 18;

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Catalyst::Test 'AmuseWikiFarm';
use Data::Dumper;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0canonicals0';
my $host = $site_id . '.amusewiki.org';

my $res = request('/', { host => 'pincopallino.org' });

is $res->code, '403', "Access forbidden against non-existent host";

my $site = create_site($schema, $site_id);

path(qw/t files shot.png/)->copy(path($site->path_for_site_files, 'navlogo.png'));
$site->index_site_files;

$res = request('/library', { host => $host });

is $res->code, '200', "After site creation, site can be accessed"
  or die;

$site->update({ canonical => 'blablabla.amusewiki.org' });
$res = request('/', { host => $host });

is $res->code, '403', "Access forbidden after canonical change";

# then add the original host to the vhost

$site->add_to_vhosts({ name => $site_id . '.amusewiki.org' });
$res = request('/', { host => $host });

is $res->code, "301", "With hostname in vhost, site can be accessed again";

is $res->header('location'), 'http://' . $site->canonical . '/';

$res = request('/library', { host => $host });

is $res->code, "301", "With hostname in vhost, site can be accessed again";

is $res->header('location'), 'http://' . $site->canonical . '/library';



is_deeply [ $site->all_site_hostnames ],
  [ "blablabla.amusewiki.org", "$site_id.amusewiki.org" ],
  "Checked all_site_hostnames";

is_deeply [ $site->alternate_hostnames ],
  [ "$site_id.amusewiki.org" ], "alternate_hostnames ok";

$site->update({ secure_site => 0 });

is $site->canonical_url, 'http://blablabla.amusewiki.org', "Url ok";
is $site->canonical_url_secure, 'http://blablabla.amusewiki.org', "Url ok";

$site->update({ secure_site => 1 });

is $site->canonical_url, 'https://blablabla.amusewiki.org', "Url ok with https";
is $site->canonical_url_secure, 'https://blablabla.amusewiki.org', "Url ok";

$site->add_to_vhosts({ name => 'example.amusewiki.org' });
$site->add_to_vhosts({ name => '00aaaa.amusewiki.org' });

is_deeply([$site->all_site_hostnames],
          ['blablabla.amusewiki.org',
           '00aaaa.amusewiki.org',
           '0canonicals0.amusewiki.org',
           'example.amusewiki.org' ])
  or diag Dumper([$site->all_site_hostnames]);

$site->site_options->update_or_create({ option_name => 'allow_hostname_aliases',
                                        option_value => 1 });

$res = request('/library', { host => $host });
is $res->code, 200;

my $canonical = $site->canonical;
unlike $res->content, qr/\Q$canonical\E/, "$canonical not found in the response";

$site->add_to_vhosts({ name => $site_id . '.amusewiki.onion' });
$site->add_to_vhosts({ name => $site_id . '.amusewiki.exit' });
$site->add_to_vhosts({ name => $site_id . '.amusewiki.i2p' });

is_deeply([ $site->all_site_hostnames_for_renewal ],
          ['blablabla.amusewiki.org',
           '00aaaa.amusewiki.org',
           '0canonicals0.amusewiki.org',
           'example.amusewiki.org' ]);

is_deeply([ $site->all_site_hostnames ],
          ['blablabla.amusewiki.org',
           '00aaaa.amusewiki.org',
           '0canonicals0.amusewiki.exit',
           '0canonicals0.amusewiki.i2p',
           '0canonicals0.amusewiki.onion',
           '0canonicals0.amusewiki.org',
           'example.amusewiki.org',
          ]);

$site->delete;
