#!perl

# This is probably a redundant test, but given that it's a delicate
# part of the code, better safe than sorry.
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 2284; # test spamming

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0authen0');

$site->update({ magic_answer => 16, magic_question => '12+4' });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $filedir = catdir($site->repo_root, qw/a at/);
make_path($filedir);
my $specialdir = catdir($site->repo_root, qw/specials/);
make_path($specialdir);
make_path 'thumbnails';
my $text = 'a-test';
my $special = 'index';
my $musebody = <<MUSE;
#title A Test
#topics myTopic
#authors myAuthor
#pubdate 2016-01-02

bla bla bla
MUSE

write_file(catfile($filedir, $text . '.muse'), $musebody);
write_file(catfile($specialdir, $special . '.muse'), "#title The Index\n\nbla bla bla\n");
write_file(catfile($site->repo_root, 'uploads', 'myup.pdf'), 'xxx');
make_path catdir('thumbnails', $site->id);
write_file(catfile('thumbnails', $site->id, 'myup.pdf.thumb.png'), 'xxx');
$site->update_db_from_tree;
my $user = $site->update_or_create_user({ username => "test-username",
                                          password => "test-username" }, 'librarian');

my $admin = $site->update_or_create_user({ username => "test-admin",
                                          password => "test-admin" }, 'admin');


# urls are collected from the debug below
my @open_for_all = ('/login',
                    '/human',
                    '/favicon.ico',
                    "/reset-password",
                    "/reset-password/asdf/asdf",
                    "/robots.txt",
                    "/opensearch.xml",
                    "/sitefiles/" . $site->id . "/favicon.ico",
                   );
my @open_if_public = ('/api/autocompletion/topic',
                      '/api/ckeditor',
                      '/archive/en',
                      '/archive',
                      '/alskdjf', # catchall
                      '/category/author',
                      '/category/author/en/myauthor/edit',
                      '/category/author/en/myauthor/delete',
                      '/authors',
                      '/topics',
                      '/category/author/en/myauthor',
                      '/cloud/authors',
                      '/cloud',
                      '/cloud/topics',
                      '/custom/asdf',
                      '/feed',
                      '/git',
                      '/help/faq',
                      '/help/irc',
                      '/help/opds',
                      '/',
                      '/latest',
                      '/library/$text/edit',
                      "/library",
                      "/library/$text",
                      "/library/$text/bbselect",
                      "/monthly",
                      "/monthly/2016/1",
                      "/monthly/2016",
                      "/opds/authors/myauthor",
                      "/opds/authors",
                      "/opds/crawlable",
                      "/opds/new",
                      "/opds/search",
                      "/opds",
                      "/opds/titles",
                      "/opds/topics",
                      "/opds/topics/mytopic",
                      "/random",
                      "/rss.xml",
                      "/search",
                      "/special",
                      "/special/$special",
                      "/sitemap.txt",
                      "/stats/popular",
                      "/stats/register",
                      "/utils/import",
                      "/uploads/" . $site->id . '/myup.pdf',
                      "/uploads/" . $site->id . '/thumbnails/myup.pdf.thumb.png',
                     );
my @human_only = (
                  '/bookbuilder/add/' . $text,
                  '/bookbuilder/clear',
                  '/bookbuilder/cover',
                  '/bookbuilder/create-profile',
                  '/bookbuilder/edit',
                  '/bookbuilder/fonts',
                  '/bookbuilder',
                  '/bookbuilder/load',
                  '/bookbuilder/profile/1',
                  '/bookbuilder/schemas',
                  # job number
                  "/tasks/status/1/ajax",
                  "/tasks/status/1",
                 );

my @editing = (
                  "/action/text/edit/$text/1/diff",
                  "/action/text/edit/$text/1",
                  "/action/text/new",
                  "/action/text/edit/$text/1/preview",
                  "/action/text/edit/$text/1/prova.png",
                  "/action/text/edit/$text");

my @publishing = (

                  "/publish/all",
                  "/publish/pending",
                  "/publish/publish",
                  "/publish/purge",
                 );
my @user_only = (
                 '/console/git/add',
                 '/console/alias/create',
                 '/console/alias/delete',
                 '/console/alias',
                 '/console/unpublished/purge',
                 '/console/git/remove',
                 '/console/translations',
                 '/console/unpublished',
                 "/special/$special/edit",
                 "/user/create",
                 "/user/edit/" . $user->id,
                 "/user/edit/" . $user->id  . '/options',
                );
my @admin_only = (
                  "/user/site/"
                 );
my @root_only = ('/admin/newuser',
                 '/admin/debug_loc',
                 '/admin/debug_site_id',
                 '/admin/jobs/delete',
                 '/admin/users/' . $user->id . '/delete',
                 '/admin/sites/edit',
                 '/admin/sites/edit/' . $site->id,
                 '/admin/users/' . $user->id . '/edit',
                 '/admin/jobs/show/',
                 '/admin/sites',
                 '/admin/users/' . $user->id,
                 '/admin/users',
                );

# TODO: do not serve files without checking if they are symlinks

# TODO: Provide routes for favicon, local.js, local.css and don't
# serve them directly

foreach my $mode (qw/private blog modwiki openwiki/) {
    $site->update({ mode => $mode });
    if ($site->mode eq 'private') {
        my $mech = fresh_mech();
        for my $i (1,2) {
            check_get_ok($mech, @open_for_all);
            check_auth_needed($mech,
                              @open_if_public, @human_only, @editing, @publishing,
                              @user_only, @admin_only, @root_only);
            $mech->get_ok('/login');
            ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
            $mech->get_ok('/') or die;
            # login then
            check_get_ok($mech, @open_if_public, @human_only, @editing, @publishing,
                         @user_only, @admin_only, @root_only);
            $mech->get('/logout');
        }
    }
    else {
        my $mech = fresh_mech();
        check_get_ok($mech, @open_for_all, @open_if_public);
        check_auth_needed($mech,
                          @human_only, @editing, @publishing,
                          @user_only, @admin_only, @root_only);
        $mech->get_ok('/human');
        $mech->content_contains('__auth_user');
        ok $mech->submit_form(with_fields => { __auth_human => 16 });
        check_get_ok($mech, @open_for_all, @open_if_public, @human_only);

        diag "Testing publishing for mode $mode";
        if ($mode eq 'openwiki') {
            check_get_ok($mech, @publishing, @editing);
        }
        elsif ($mode eq 'modwiki') {
            check_get_ok($mech, @editing);
            check_auth_needed($mech, @publishing);
        }
        elsif ($mode eq 'blog') {
            check_auth_needed($mech, @publishing, @editing);
        }
        else {
            die;
        }
        check_auth_needed($mech,
                          @user_only, @admin_only, @root_only);
        $mech->get_ok('/login');
        ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
        check_get_ok($mech, @publishing, @editing,
                     @admin_only,
                     @user_only, @admin_only, @root_only);
        $mech->get('/logout');

        $mech->get_ok('/login');
        ok $mech->submit_form(with_fields => {__auth_user => 'test-admin', __auth_pass => 'test-admin' }) or die;
        check_get_ok(@admin_only);
        $mech->get('/logout');
        $mech->get_ok('/login');
        ok $mech->submit_form(with_fields => {__auth_user => 'test-username', __auth_pass => 'test-username' }) or die;
        foreach my $path (@admin_only) {
            $mech->get($path);
            is $mech->status, 403, "Access denied";
        }
        $mech->get('/logout');
    }
}

sub fresh_mech {
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get('/');
    return $mech;
}

sub check_auth_needed {
    my ($mech, @paths) = @_;
    foreach my $path (@paths) {
        $mech->get($path);
        is $mech->status, 401, "$path is 401" or die;
        $mech->content_contains('__auth', "auth form found in $path") or die;
    }
}

sub check_get_ok {
    my ($mech, @paths) = @_;
    foreach my $path (@paths) {
        $mech->get($path);
        like ($mech->status, qr{(200|404|403)}, "Acceptable status for $path? " . $mech->status)
          or die;
        unless ($path eq '/login' or $path eq '/human') {
            $mech->content_lacks('__auth', "auth form not found in $path") or die;
        }
    }
}




$user->delete;
$admin->delete;
$site->delete;
