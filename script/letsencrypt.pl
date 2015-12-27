#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm;

my $schema = AmuseWikiFarm->model('DB');

my @sites = $schema->resultset('Site')->active_only->all;

my $confgenerator = AmuseWikiFarm->model('Webserver');

print $confgenerator->generate_letsencrypt_cronjob(@sites);
