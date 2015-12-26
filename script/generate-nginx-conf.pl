#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm;

my $schema = AmuseWikiFarm->model('DB');

my @sites = $schema->resultset('Site')->search(undef, { order_by => [qw/id/],
                                                        prefetch => 'vhosts'})
  ->all;

my $confgenerator = AmuseWikiFarm->model('Webserver');
if (my $out = $confgenerator->generate_nginx_config(@sites)) {
    print "# please execute as root:\n";
}
else {
    print "# no action required, nginx configuration is up-to-date\n";
}


