use strict;
use warnings;
use Test::More tests => 17;

use Catalyst::Test 'AmuseWikiFarm';
use Test::WWW::Mechanize::Catalyst;

my %hosts = (
             'blog.amusewiki.org' => {
                                      id => '0blog0',
                                      locale => 'hr',
                                     },
             'test.amusewiki.org' => {
                                      id => '0test0',
                                      locale => 'en',
                                     }
            );


foreach my $host (keys %hosts) {
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $host);
    $mech->get('/admin/debug_site_id');
    ok (!$mech->success, "Not a success");
    is ($mech->status, 403);
    $mech->get_ok('/login');
    $mech->content_contains('name="password"');
    $mech->content_contains('name="username"');
    $mech->submit_form(form_id => 'login-form',
                       fields => { username => 'root',
                                   password => 'root',
                                 },
                       button => 'submit');
    $mech->get_ok('/admin/debug_site_id');
    $mech->content_is($hosts{$host}{id} . ' ' . $hosts{$host}{locale}) or
      print $mech->content;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

diag "Regular users can't access admin";

$mech->get('/logout');
$mech->get('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'user1',
                               password => 'pass',
                             },
                   button => 'submit');
$mech->get('/');
$mech->content_contains("/logout");
$mech->get('/admin/debug_site_id');
ok (!$mech->success, "Not a success");
is ($mech->status, 403);

