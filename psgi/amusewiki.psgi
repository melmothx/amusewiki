use strict;
use warnings;
use lib 'lib';
use AmuseWikiFarm;

my $app = AmuseWikiFarm->apply_default_middlewares(AmuseWikiFarm->psgi_app);
$app;

