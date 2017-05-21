#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 50;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $sid = '0sku0';
my $site = $schema->resultset('Site')->find($sid);
unless ($site) {
    $site = create_site($schema, $sid);
    $site->update({ secure_site => 0, epub => 1 });
    foreach my $prefix ('first', 'second') {
        foreach my $i (95..102) {
            my $sku = sprintf('%s-%.6d', $prefix, $i);
            foreach my $add_sku (0..1) {
                my ($rev) = $site->create_new_text({ title => "Prefix $i SKU $sku $add_sku",
                                                     textbody => '<p>ciao</p>',
                                                     ($add_sku ? (cat => $prefix,
                                                                  author => $prefix) : ()),
                                                   }, 'text');
                $rev->edit("#sku   $sku   \n" . $rev->muse_body) if $add_sku;
                $rev->commit_version;
                $rev->publish_text;
            }
        }
    }
}
$site->site_options->delete;
ok $site->titles->search({ sku => '' })->count;
foreach my $text ($site->titles->search({ sku => { '!=' => '' } })) {
    ok $text->sku;
    diag $text->sku;
    like $text->sku, qr/\A[a-zA-Z0-9-]+\z/, "Sku stripped from trailing and leading whitespace";
}

is $site->titles->search({ sku => { "!=" => '' } })->order_by('sku_asc')->first->sku, 'first-000095';
is $site->titles->order_by('sku_desc')->first->sku, 'second-000102';

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/login');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->content_contains('You are logged in now!');

diag "Checking if the option pops up";
$mech->get_ok('/category/author/first');
$mech->content_lacks('sku_desc');
$mech->content_lacks('sku_asc');
$mech->get_ok('/user/site');
$mech->content_lacks('sku_desc');
$mech->content_lacks('sku_asc');
$mech->submit_form(with_fields => { enable_order_by_sku => '1' },
                   button => 'edit_site');
$mech->get_ok('/user/site');
$mech->content_contains('sku_desc');
$mech->content_contains('sku_asc');
$mech->get_ok('/category/author/first');
$mech->content_contains('sku_desc');
$mech->content_contains('sku_asc');




