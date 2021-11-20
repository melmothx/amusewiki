BEGIN {
    die "Do not run this as root" unless $>;
}
use strict;
use warnings;
use Plack::Builder;
use lib 'lib';
use AmuseWikiFarm;

my $app = AmuseWikiFarm->apply_default_middlewares(AmuseWikiFarm->psgi_app);

builder {
    enable "Plack::Middleware::Static",
      path => qr{^/static/}, root => 'root/';
    $app;   
};


