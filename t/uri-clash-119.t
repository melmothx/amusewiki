#perl

use utf8;
use strict;
use warnings;
use Test::More tests => 22;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $exist = $site->titles->status_is_not_published->first;
ok $exist;
diag $exist->full_uri;
$mech->get($exist->full_uri);
is $mech->status, 404;

$mech->get('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';

$mech->get('/action/text/new?__language=en');

$mech->content_contains('name="uri"');
$mech->content_unlike(qr{name="uri".*name="uri"}s);

ok($mech->form_with_fields('title'));
$mech->field('title' => $exist->uri);
$mech->field('texthtmlfile' => catfile(qw/t files upload.html/));
$mech->click;
$mech->content_contains('Such an URI already exists');
$mech->content_contains('Please upload your file again');
$mech->content_contains('name="uri"');
$mech->content_unlike(qr{name="uri".*name="uri"}s);

ok($mech->form_with_fields('title'));
$mech->field('title' => $exist->uri);
$mech->click;
diag $mech->uri;
$mech->content_contains('Such an URI already exists');
$mech->content_lacks('Please upload your file again');
$mech->content_contains('name="uri"');
$mech->content_unlike(qr{name="uri".*name="uri"}s);
ok($mech->form_with_fields('title'));
$mech->field(uri => $exist->uri);
$mech->click;
diag $mech->uri;
$mech->content_contains('Such an URI already exists');
$mech->content_lacks('Please upload your file again');
$mech->content_contains('name="uri"');
$mech->content_unlike(qr{name="uri".*name="uri"}s);
ok($mech->form_with_fields('title'));
$mech->field(uri => $exist->uri . '-' . time());
$mech->click;
ok($mech->form_id('museform'));
diag $mech->uri;

$site->revisions->delete;

