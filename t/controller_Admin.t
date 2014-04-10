use strict;
use warnings;
use Test::More tests => 8;

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

    $mech->get_ok('/admin/pending');
    $mech->content_contains('<input type="password" name="password"');
    $mech->post('/login' => { username => 'root',
                              password => 'root',
                              submit => '1',
                            });
    $mech->get_ok('/admin/debug_site_id');
    $mech->content_is($hosts{$host}{id} . ' ' . $hosts{$host}{locale}) or
      print $mech->content;
}
