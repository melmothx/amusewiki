#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 30;
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
my $site_id = '0edit1';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({ secure_site => 0 });
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$mech->get_ok('/action/text/new');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;
$mech->content_contains('You are logged in now!');

foreach my $console ('/publish/pending', '/publish/all') {
    diag "Uploading a text";
    $mech->get_ok('/action/text/new');
    my $title = 'test rev deletion';
    ok($mech->form_id('ckform'), "Found the form for uploading stuff");
    $mech->set_fields(author => 'pippo',
                      title => $title,
                      textbody => "blablabla\n");

    $mech->click;

    $mech->content_contains('Created new text');

    ok($mech->form_id('museform'), "Found the muse form");
    ok($mech->click('commit'), "Committed");
    is($mech->uri->path, '/publish/pending', "In publish/pending");
    $mech->get_ok($console);
    $mech->content_contains('name="delete"');
    $mech->content_contains('test-rev-deletion');
    ok($mech->form_name('deletion'), "Found the form name");
    $mech->click;
    $mech->content_lacks('name="delete"');
    $mech->content_like(qr{Revision for .*test-rev-deletion.*has been deleted});
    is($mech->uri->path, $console, "In the right path ($console)");
}
