BEGIN {
    die "Do not run this as root" unless $>;
}
use strict;
use warnings;
use lib 'lib';
use AmuseWikiMeta;

my $app = AmuseWikiMeta->apply_default_middlewares(AmuseWikiMeta->psgi_app);
$app;

