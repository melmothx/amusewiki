use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };



BEGIN { use_ok 'AmuseWikiFarm::Model::DB' }

done_testing();
