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
use Test::More tests => 22;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0authen0');

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
my @open_for_all = ('/login/',
                    '/human',
                    '/favicon.ico',
                    "/logout",
                    "/reset-password",
                    "/reset-password/asdf/asdf",
                    "/robots.txt",
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
                      "/opensearch.xml",
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
                  "/library/$text/bbselect",
                  # job number
                  "/tasks/status/1/ajax",
                  "/tasks/status/1",
                 );
my @publishing = (
                  "/action/text/edit/$text/1/diff",
                  "/action/text/edit/$text/1",
                  "/action/text/new",
                  "/action/text/edit/$text/1/preview",
                  "/action/text/edit/$text/1/prova.png",
                  "/action/text/edit/$text",
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
                 "/special",
                 "/special/$special",
                 "/user/create",
                 "/user/edit/" . $user->id,
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






# 2016/10/19 15:05:39 DEBUG - AmuseWikiFarm.Log.Contextual.App - App.pm:16 - Loaded Chained actions:
# .---------------------------------------------+----------------------------------------------.
# | Path Spec                                   | Private                                      |
# +---------------------------------------------+----------------------------------------------+
# | /admin/newuser                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | => /admin/create_user                        |
# | /admin/debug_loc                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | => /admin/debug_loc                          |
# | /admin/debug_site_id                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | => /admin/debug_site_id                      |
# | /admin/jobs/delete                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/get_jobs (0)                       |
# |                                             | => /admin/delete_job                         |
# | /admin/users/*/delete                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/users (0)                          |
# |                                             | -> /admin/user_details (1)                   |
# |                                             | => /admin/delete_user                        |
# | /admin/sites/edit/...                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/sites (0)                          |
# |                                             | => /admin/edit                               |
# | /admin/users/*/edit                         | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/users (0)                          |
# |                                             | -> /admin/user_details (1)                   |
# |                                             | => /admin/edit_user_details                  |
# | /admin/jobs/show/...                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/get_jobs (0)                       |
# |                                             | => /admin/jobs                               |
# | /admin/sites                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/sites (0)                          |
# |                                             | => /admin/list                               |
# | /admin/users/*                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/users (0)                          |
# |                                             | -> /admin/user_details (1)                   |
# |                                             | => /admin/show_user_details                  |
# | /admin/users                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /admin/root (0)                           |
# |                                             | -> /admin/users (0)                          |
# |                                             | => /admin/show_users                         |
# | /api/autocompletion/*                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /api/api (0)                              |
# |                                             | => /api/autocompletion                       |
# | /api/ckeditor                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /api/api (0)                              |
# |                                             | => /api/ckeditor                             |
# | /archive/*                                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /archive/pre_base (0)                     |
# |                                             | -> /archive/base (0)                         |
# |                                             | => /archive/archive_by_lang                  |
# | /archive                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /archive/pre_base (0)                     |
# |                                             | -> /archive/base (0)                         |
# |                                             | => /archive/listing                          |
# | /bookbuilder/add/*                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/add                          |
# | /bookbuilder/clear                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/clear                        |
# | /bookbuilder/cover                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/cover                        |
# | /bookbuilder/create-profile                 | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/create_profile               |
# | /bookbuilder/edit                           | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/edit                         |
# | /bookbuilder/fonts                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/fonts                        |
# | /bookbuilder                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/index                        |
# | /bookbuilder/load                           | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/load                         |
# | /bookbuilder/profile/*                      | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/profile                      |
# | /bookbuilder/schemas                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /bookbuilder/root (0)                     |
# |                                             | => /bookbuilder/schemas                      |
# | /...                                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /catch_all                                |
# | /category/*                                 | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | -> /category/category (1)                    |
# |                                             | => /category/category_list_display           |
# | /category/*/*/*/delete                      | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | -> /category/category (1)                    |
# |                                             | -> /category/single_category (1)             |
# |                                             | -> /category/single_category_by_lang (1)     |
# |                                             | -> /category/category_editing_auth (0)       |
# |                                             | => /category/delete_category_by_lang         |
# | /category/*/*/*/edit                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | -> /category/category (1)                    |
# |                                             | -> /category/single_category (1)             |
# |                                             | -> /category/single_category_by_lang (1)     |
# |                                             | -> /category/category_editing_auth (0)       |
# |                                             | => /category/edit_category_description       |
# | /authors/...                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | => /category/legacy_authors                  |
# | /topics/...                                 | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | => /category/legacy_topics                   |
# | /category/*/*/*                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | -> /category/category (1)                    |
# |                                             | -> /category/single_category (1)             |
# |                                             | -> /category/single_category_by_lang (1)     |
# |                                             | => /category/single_category_by_lang_display |
# | /category/*/*                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /category/root (0)                        |
# |                                             | -> /category/category (1)                    |
# |                                             | -> /category/single_category (1)             |
# |                                             | => /category/single_category_display         |
# | /cloud/authors                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /cloud/base (0)                           |
# |                                             | => /cloud/authors                            |
# | /cloud                                      | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /cloud/base (0)                           |
# |                                             | => /cloud/show                               |
# | /cloud/topics                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /cloud/base (0)                           |
# |                                             | => /cloud/topics                             |
# | /console/git/add                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/git (0)                          |
# |                                             | => /console/add_git_remote                   |
# | /console/alias/create                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/alias (0)                        |
# |                                             | => /console/alias_create                     |
# | /console/alias/delete                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/alias (0)                        |
# |                                             | => /console/alias_delete                     |
# | /console/alias                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/alias (0)                        |
# |                                             | => /console/alias_display                    |
# | /console/git/action                         | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/git (0)                          |
# |                                             | => /console/git_action                       |
# | /console/git                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/git (0)                          |
# |                                             | => /console/git_display                      |
# | /console/unpublished/purge                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/unpublished_list (0)             |
# |                                             | => /console/purge                            |
# | /console/git/remove                         | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/git (0)                          |
# |                                             | => /console/remove_git_remote                |
# | /console/translations                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | => /console/translations                     |
# | /console/unpublished                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /console/root (0)                         |
# |                                             | -> /console/unpublished_list (0)             |
# |                                             | => /console/unpublished                      |
# | /custom/*                                   | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /custom/root (0)                          |
# |                                             | => /custom/custom                            |
# | /action/*/edit/*/*/diff                     | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | -> /edit/text (1)                            |
# |                                             | -> /edit/get_revision (1)                    |
# |                                             | => /edit/diff                                |
# | /action/*/edit/*/*                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | -> /edit/text (1)                            |
# |                                             | -> /edit/get_revision (1)                    |
# |                                             | => /edit/edit                                |
# | /action/*/new                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | => /edit/newtext                             |
# | /action/*/edit/*/*/preview                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | -> /edit/text (1)                            |
# |                                             | -> /edit/get_revision (1)                    |
# |                                             | => /edit/preview                             |
# | /action/*/edit/*/*/*                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | -> /edit/text (1)                            |
# |                                             | -> /edit/get_revision (1)                    |
# |                                             | => /edit/preview_attachment                  |
# | /action/*/edit/*                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /edit/root (1)                            |
# |                                             | -> /edit/text (1)                            |
# |                                             | => /edit/revs                                |
# | /favicon.ico                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /favicon                                  |
# | /feed                                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /feed/index                               |
# | /git/...                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /git/git                                  |
# | /help/faq                                   | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /help/root (0)                            |
# |                                             | => /help/faq                                 |
# | /help/irc                                   | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /help/root (0)                            |
# |                                             | => /help/irc                                 |
# | /help/opds                                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /help/root (0)                            |
# |                                             | => /help/opds                                |
# | /                                           | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /index                                    |
# | /latest/...                                 | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /latest/pre_base (0)                      |
# |                                             | -> /latest/base (0)                          |
# |                                             | => /latest/index                             |
# | /library/*/bbselect                         | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /library/pre_base (0)                     |
# |                                             | -> /library/base (0)                         |
# |                                             | -> /library/match (1)                        |
# |                                             | => /library/bbselect                         |
# | /library/*/edit                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /library/pre_base (0)                     |
# |                                             | -> /library/base (0)                         |
# |                                             | -> /library/match (1)                        |
# |                                             | => /library/edit                             |
# | /library                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /library/pre_base (0)                     |
# |                                             | -> /library/base (0)                         |
# |                                             | => /library/listing                          |
# | /library/*                                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /library/pre_base (0)                     |
# |                                             | -> /library/base (0)                         |
# |                                             | -> /library/match (1)                        |
# |                                             | => /library/text                             |
# | /monthly                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /monthly/base (0)                         |
# |                                             | => /monthly/list                             |
# | /monthly/*/*                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /monthly/base (0)                         |
# |                                             | -> /monthly/year (1)                         |
# |                                             | => /monthly/month                            |
# | /monthly/*                                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /monthly/base (0)                         |
# |                                             | -> /monthly/year (1)                         |
# |                                             | => /monthly/year_display                     |
# | /opds/authors/...                           | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | -> /opds/all_authors (0)                     |
# |                                             | => /opds/author                              |
# | /opds/authors                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | -> /opds/all_authors (0)                     |
# |                                             | => /opds/authors                             |
# | /opds/crawlable                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | => /opds/crawlable                           |
# | /opds/new/...                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | => /opds/new_entries                         |
# | /opds/search                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | => /opds/search                              |
# | /opds                                       | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | => /opds/start                               |
# | /opds/titles/...                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | => /opds/titles                              |
# | /opds/topics/...                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | -> /opds/all_topics (0)                      |
# |                                             | => /opds/topic                               |
# | /opds/topics                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /opds/root (0)                            |
# |                                             | -> /opds/clean_root (0)                      |
# |                                             | -> /opds/all_topics (0)                      |
# |                                             | => /opds/topics                              |
# | /publish/all                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /publish/root (0)                         |
# |                                             | => /publish/all                              |
# | /publish/pending                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /publish/root (0)                         |
# |                                             | => /publish/pending                          |
# | /publish/publish                            | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /publish/root (0)                         |
# |                                             | -> /publish/validate_revision (0)            |
# |                                             | => /publish/publish                          |
# | /publish/purge                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /publish/root (0)                         |
# |                                             | -> /publish/validate_revision (0)            |
# |                                             | => /publish/purge                            |
# | /random                                     | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /random                                   |
# | /robots.txt                                 | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | => /robots_txt                               |
# | /rss.xml                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /rss_xml                                  |
# | /search                                     | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /search/index                             |
# | /opensearch.xml                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | => /search/opensearch                        |
# | /sitefiles/*/*                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /sitefiles/root (1)                       |
# |                                             | => /sitefiles/local_files                    |
# | /sitemap.txt                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /sitemap_txt                              |
# | /special/*/edit                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /special/base (0)                         |
# |                                             | -> /special/match (1)                        |
# |                                             | => /special/edit                             |
# | /special                                    | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /special/base (0)                         |
# |                                             | => /special/listing                          |
# | /special/*                                  | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /special/base (0)                         |
# |                                             | -> /special/match (1)                        |
# |                                             | => /special/text                             |
# | /stats/popular/...                          | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /stats/stats (0)                          |
# |                                             | => /stats/popular                            |
# | /stats/register                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_robot_index (0)                     |
# |                                             | -> /stats/stats (0)                          |
# |                                             | => /stats/register                           |
# | /tasks/status/*/ajax                        | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /tasks/root (0)                           |
# |                                             | -> /tasks/status (1)                         |
# |                                             | => /tasks/ajax                               |
# | /tasks/status/*                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_human_required (0)                  |
# |                                             | -> /tasks/root (0)                           |
# |                                             | -> /tasks/status (1)                         |
# |                                             | => /tasks/display                            |
# | /uploads/*/*                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /uploads/root (1)                         |
# |                                             | -> /uploads/upload (1)                       |
# |                                             | => /uploads/pdf                              |
# | /uploads/*/thumbnails/*                     | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /uploads/root (1)                         |
# |                                             | => /uploads/thumbnail                        |
# | /user/create                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /user/user (0)                            |
# |                                             | => /user/create                              |
# | /user/edit/*                                | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /user/user (0)                            |
# |                                             | => /user/edit                                |
# | /human                                      | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /user/human                               |
# | /login                                      | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /secure_no_user (0)                       |
# |                                             | => /user/login                               |
# | /logout                                     | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | => /user/logout                              |
# | /reset-password                             | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /secure_no_user (0)                       |
# |                                             | => /user/reset_password                      |
# | /reset-password/*/*                         | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /secure_no_user (0)                       |
# |                                             | => /user/reset_password_confirm              |
# | /user/site/...                              | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /site_user_required (0)                   |
# |                                             | -> /user/user (0)                            |
# |                                             | => /user/site_config                         |
# | /utils/import                               | /check_unicode_errors (0)                    |
# |                                             | -> /site_no_auth (0)                         |
# |                                             | -> /site (0)                                 |
# |                                             | -> /utils/root (0)                           |
# |                                             | => /utils/import                             |
# '---------------------------------------------+----------------------------------------------'
# 


$user->delete;
$admin->delete;
$site->delete;
