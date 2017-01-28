#!perl

use utf8;
use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cformats0';
my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get('/settings/formats');
is $mech->status, '401';
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';
my $name = "my custom format";
$mech->submit_form(with_fields => {
                                   format_name => $name,
                                  });
$mech->content_contains($name);
is $site->custom_formats->active_only->count, 1, "format created";
my $cf = $site->custom_formats->first;

$mech->get_ok('/settings/formats');
$mech->submit_form(form_id => 'format-activate-' . $cf->custom_formats_id );
$mech->get_ok('/admin/sites/edit/' . $site->id) or die;
$mech->content_lacks($name);
$mech->get_ok('/user/site');
$mech->content_lacks($name);

$mech->get_ok('/settings/formats');
$mech->submit_form(form_id => 'format-activate-' . $cf->custom_formats_id);
$mech->get_ok('/admin/sites/edit/' . $site->id);
$mech->content_contains($name);
$mech->get_ok('/user/site');
$mech->content_contains($name);

$site->delete;
is($schema->resultset('CustomFormat')->search({ site_id => $site_id })->count, 0,
   "Custom format is gone after site deletion");
done_testing;
