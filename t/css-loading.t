#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Data::Dumper::Concise;
use Test::More tests => 11;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
# cleanup
$site->revisions->delete_all;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $mk_css = '/static/js/markitup/skins/amw/style.css';

$mech->get_ok('/');
diag "At root";
$mech->content_lacks($mk_css);

$mech->get_ok('/login');
ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
   "Found login form");
is $mech->status, '200';

foreach my $type (qw/special text/) {
    $mech->get("/action/$type/new");
    diag $mech->uri;
    $mech->content_lacks($mk_css);

    $mech->submit_form(with_fields => {title => 'this-is-a-test-' . $type},
                       button => 'go',
                      );
    diag $mech->uri;
    $mech->content_contains($mk_css);
}

$mech->get('/category/author/ciao/edit');
diag $mech->uri;
$mech->content_contains($mk_css);

$mech->get('/category/topic/miao/edit');
diag $mech->uri;
$mech->content_contains($mk_css);

diag Dumper([$site->bootstrap_themes]);
diag Dumper([$site->bootstrap_theme_list]);
