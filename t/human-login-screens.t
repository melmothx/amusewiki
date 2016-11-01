#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use strict;
use warnings;
use Test::More tests => 24;
use File::Spec::Functions qw/catfile catdir/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0hls0');

my @open = ('/library', '/latest', '/feed', '/category/author', '/category/topic');
my @human;
my @admins;

foreach my $mode (qw/private blog modwiki openwiki/) {
    $site->update({ mode => $mode });
    foreach my $url (@open) {
        my $mech = Test::WWW::Mechanize::Catalyst
          ->new(catalyst_app => 'AmuseWikiFarm',
                agent => 'Mozilla/5.0 (X11; Linux x86_64; rv:38.0) Gecko/20100101 Firefox/38.0 Iceweasel/38.8.0',
                agent_alias => 'Windows IE 6',
                host => $site->canonical);
        if ($mode eq 'private') {
            $mech->get($url);
            is $mech->status, 401;
            $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'x' });
            $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
            is $mech->status, 200, "$url is fine";
            is $mech->uri->path, $url;
            $mech->content_contains('logged in now') if $mech->response->content_type eq 'text/html';
            $mech->content_lacks('__auth_user');
        }
    }
}
