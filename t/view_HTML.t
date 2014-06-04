use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };



BEGIN { use_ok 'AmuseWikiFarm::View::HTML' }

done_testing();
