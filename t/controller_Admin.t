use strict;
use warnings;
use Test::More tests => 109;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper;
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

my $schema = AmuseWikiFarm::Schema->connect('amuse');

foreach my $host (keys %hosts) {
    $schema->resultset('Site')->find($hosts{$host}{id})->update({ locale => $hosts{$host}{locale} });
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $host);
    $mech->get_ok('/');
    $mech->get('/admin/debug_site_id');
    is $mech->status, 401;
    $mech->submit_form(with_fields => { __auth_user => 'root',
                                        __auth_pass => 'root',
                                  });
    is ($mech->uri->path, '/admin/debug_site_id');
    $mech->content_is($hosts{$host}{id} . ' ' . $hosts{$host}{locale}) or
      diag $mech->content;
    my $site = $schema->resultset('Site')->find($hosts{$host}{id});
    for (1..50) {
        $site->jobs->enqueue(testing => { this => 1, test => 1  });
    }
    $mech->get_ok("/admin/jobs/show?field=status&search=pending");
    my $content = $mech->content;
    my $matches = () = $content =~ m/testing.*?pending/gs;
    ok ($matches, "Found $matches matches of jobs");
    is $matches, 10, "Found paginated result";
    $mech->content_contains('class="pagination"');
    my @links = grep { $_->url =~ m{/admin/jobs/} } $mech->find_all_links;
    $mech->links_ok(\@links);
    ok(scalar(@links), "Found and tested " . scalar(@links) . " links");
    diag Dumper([ map { $_->url } @links ]);
    $site->jobs->delete;
}
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

diag "Regular users can't access admin";

$mech->get('/logout');
$mech->get('/login');
$mech->submit_form(with_fields => { __auth_user => 'user1', __auth_pass => 'pass' });
$mech->get('/');
$mech->content_contains("/logout");
$mech->get('/admin/debug_site_id');
ok (!$mech->success, "Not a success");
is ($mech->status, 403, "403 because it's logged in, but not an admin");

$mech->get('/logout');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
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


foreach my $sitespec ({
                       create_site => 'alsdflkj laksjdflkaksd asdfasdf',
                       canonical => 'my.site.org',
                      },
                      {
                       create_site => '0invalid0',
                       canonical => 'my site.org',
                      },
                      {
                       create_site => 'thisisinvalidbecauseitsverylong',
                       canonical => 'my.site-wiki.org',
                      }) {
    $mech->get_ok('/admin/sites');
    $mech->submit_form(form_id => 'creation-site-form',
                       fields => $sitespec);
    ok(!$schema->resultset('Site')->find($sitespec->{create_site}), "name is invalid");
    ok(!$mech->form_with_fields(qw/mode locale/), "Form not found");
    ok($mech->content_contains('error_message'), "Found the error message");
}

foreach my $sitespec ({
                       id => '0xcreate0',
                       canonical => '0xcreate0.amusewiki.org',
                      },
                      {
                       id => '0withdash0',
                       canonical => '0withdash0-wiki.org',
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
    ok($mech->content_lacks('error_message'));
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
