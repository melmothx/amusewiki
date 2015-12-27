#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm;

my $schema = AmuseWikiFarm->model('DB');

my @sites = $schema->resultset('Site')->active_only->all;

my $confgenerator = AmuseWikiFarm->model('Webserver');

print "# Updating let's encrypt cronjob " . $confgenerator->letsencrypt_cronjob_path . "\n";
$confgenerator->update_letsencrypt_cronjob(@sites);


if (my $out = $confgenerator->generate_nginx_config(@sites)) {
    print "# please execute as root:\n";
    print $out;
}
else {
    print "# no action required, nginx configuration is up-to-date\n";
}


