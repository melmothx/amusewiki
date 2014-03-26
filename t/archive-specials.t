use strict;
use warnings;

use Test::More;
use Data::Dumper;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Special;
my $db = AmuseWikiFarm::Schema->connect('amuse');

my $site = $db->resultset('Site')->find('0blog0');

my $special = AmuseWikiFarm::Archive::Special->new(site_schema => $site);

ok $special->basedir, "Found " . $special->basedir;
ok -d $special->basedir, "Directory exists";

is $special->special_dir, 'specials';

like $special->muse_dir, qr/0blog0/;
ok -d $special->muse_dir;
ok $special->path_to_muse('index'), "found " . $special->path_to_muse('index');
ok -f $special->path_to_muse('index'), "index found and exists";

done_testing;
