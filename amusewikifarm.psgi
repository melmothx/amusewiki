use strict;
use warnings;

use AmuseWikiFarm;

my $app = AmuseWikiFarm->apply_default_middlewares(AmuseWikiFarm->psgi_app);
$app;

