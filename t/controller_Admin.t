use strict;
use warnings;
use Test::More tests => 62;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Path qw/remove_tree/;

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
    $mech->get_ok('/admin/debug_site_id');
    is ($mech->uri->path, '/login');
    $mech->content_contains('name="password"');
    $mech->content_contains('name="username"');
    $mech->submit_form(form_id => 'login-form',
                       fields => { username => 'root',
                                   password => 'root',
                                 },
                       button => 'submit');
    is ($mech->uri->path, '/admin/debug_site_id');
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

$mech->get('/logout');
$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');

$mech->get_ok('/admin/sites/edit/0blog0');

my $html_injection = q{<script>alert('hullo')</script>};
my $links = <<LINKS;
http://sandbox.amusewiki.org Sandbox
http://www.amusewiki.org WWW
LINKS


$mech->submit_form(with_fields => {
                                   html_special_page_bottom => $html_injection,
                                   site_links => $links,
                                  },
                   button => 'edit_site');

$mech->get_ok('/special/index');
$mech->content_contains($html_injection, "Found HTML");
$mech->content_contains('<a href="http://sandbox.amusewiki.org">Sandbox</a>');
$mech->content_contains('<a href="http://www.amusewiki.org">WWW</a>');

$mech->get_ok('/admin/sites/edit/0blog0');
$mech->submit_form(with_fields => {
                                   html_special_page_bottom => '',
                                   site_links => '',
                                  },
                   button => 'edit_site');
$mech->get_ok('/special/index');
$mech->content_lacks($html_injection, "HTML wiped");
$mech->content_lacks('<a href="http://sandbox.amusewiki.org">Sandbox</a>');
$mech->content_lacks('<a href="http://www.amusewiki.org">WWW</a>');


my $schema = AmuseWikiFarm::Schema->connect('amuse');

foreach my $sitespec ({
                       id => '0xcreate0',
                       canonical => '0xcreate0.amusewiki.org',
                      },
                      {
                       id => 'de',
                       canonical => 'mygermanlib.org',
                      }) {
    my $site_id = $sitespec->{id};

    if (my $site = $schema->resultset('Site')->find($site_id)) {
        diag "Deleting existing site $site_id";
        $site->delete;
    }



    $mech->get_ok('/admin/sites');
    $mech->submit_form(form_id => 'creation-site-form',
                       fields => {
                                  create_site => $site_id,
                                  canonical => $sitespec->{canonical},
                                 });

    my $created = $schema->resultset('Site')->find($site_id);
    ok( $created, "Site created");

    ok(!$created->acme_certificate, "Default is false for acme cert");
    is $mech->uri->path, "/admin/sites/edit/$site_id", "Path is fine";

    $mech->content_contains(" $site_id</h1>");

    ok($mech->form_with_fields(qw/mode locale/), "Found form") or diag $mech->content;

    $mech->submit_form(with_fields => {
                                       locale => 'en',
                                       mail_notify => 'me@amusewiki.org',
                                       mail_from => 'noreply@amusewiki.org',
                                       acme_certificate => 1,
                                      },
                       button => 'edit_site');

    is $mech->uri->path, "/admin/sites/edit/$site_id";
    $mech->content_lacks(q{id="error_message"});
    is $mech->status, '200', "Request ok";
    $mech->get_ok('/admin/sites');

    $mech->content_contains('noreply@amusewiki.org', "Found the mail")
      or diag $mech->content;
    $mech->content_contains('me@amusewiki.org', "Found the mail (2)");

    $mech->get_ok("/admin/sites/edit/$site_id");

    $mech->content_contains('noreply@amusewiki.org', "Found the mail");
    $mech->content_contains('me@amusewiki.org', "Found the mail (2)");
    $created->discard_changes;
    ok( $created->acme_certificate, "Option picked up");
    my $created_root = $created->repo_root;
    ok (-d $created_root, "Repo root created");
    ok ($created->git, "Created site has a git");
    $created->delete;
    remove_tree($created_root);
}
