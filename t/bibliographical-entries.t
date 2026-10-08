#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
};

use Test::More tests => 5;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0biblioentry0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
ok ($site);
diag Dumper($site->spreadsheet_catalog_specification);
$mech->get('/console/upload-catalog-spreadsheet');
is $mech->status, 401;
ok $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' }), "Logged in";
$mech->get_ok('/console/upload-catalog-spreadsheet');
$mech->get_ok('/console/download-catalog-spreadsheet');
diag $mech->content;

# we want an export/import here. So they do the first upload with
# their sheet and they can get it back converted. Also good for
# backup.
