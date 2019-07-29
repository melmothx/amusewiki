#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 31;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0revs0');
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

ok $site->express_publishing;
foreach my $k (qw/id mode last_updated/) {
    eval {
        $site->update_option_value($k => 'asdfad');
    };
    ok $@, "$k is reserved";
}

is $site->sitegroup, '';
is $site->express_publishing, 0;
$site->update_option_value(sitegroup => 'xxxx');
$site->update_option_value(express_publishing => 1);
$site = $site->get_from_storage;
is $site->sitegroup, 'xxxx';
is $site->express_publishing, 1;
