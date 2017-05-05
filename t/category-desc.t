#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 146;

use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0catdesc0';
my $site = create_site($schema, $site_id);
$site->update({
               pdf => 0,
               multilanguage => 'en it hr',
               secure_site => 0,
              });
my ($revision) = $site->create_new_text({ uri => 'the-text',
                                          title => 'Hello',
                                          lang => 'hr',
                                          textbody => '',
                                        }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n#lang en\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
my $uri = $revision->publish_text;
ok $uri, "Found uri $uri";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");


foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->with_texts->by_type_and_uri(@$uri);
    my $full_uri = $cat->full_uri;
    ok ($cat, "Found $full_uri");
    ok ($cat->text_count, "$full_uri has " . $cat->text_count . " texts");
    $cat->category_descriptions->update_description(en => "$full_uri : this is just a *test*");
    {
        my $desc = $cat->category_descriptions->find({ lang => 'en' });
        is $desc->last_modified_by, undef, "Last modified by is undef";
    }
    $cat->category_descriptions->update_description(hr => "$full_uri : ovo je samo *test*", "pallino");
    my $regexp_en = qr{<p>\s*\Q$full_uri\E : this is just a <em>test</em>\s*</p>}s;
    my $regexp_hr = qr{<p>\s*\Q$full_uri\E : ovo je samo <em>test</em>\s*</p>}s;
    {
        my $desc = $cat->category_descriptions->find({ lang => 'en' });
        like $desc->html_body, $regexp_en, "found the HTML description";
    }
    {
        my $desc = $cat->localized_desc('en')->html_body;
        like $desc, $regexp_en, "localized_desc works";
        is $cat->localized_desc('en')->last_modified_by, undef, "en author is null";
    }
    is $cat->localized_desc('hr')->last_modified_by, "pallino",
      "hr author is pallino";
    ok !$cat->localized_desc('it'), "No desc for italian";
    $mech->get_ok('/?__language=en');
    $mech->get_ok($cat->full_uri);
    $mech->content_like($regexp_en, "found the HTML description");
    $mech->get_ok('/?__language=it');
    $mech->get_ok($cat->full_uri);
    $mech->content_unlike($regexp_en, "HTML description");
    $mech->content_unlike($regexp_hr, "HTML description");
    $mech->get_ok('/?__language=hr');
    $mech->get_ok($cat->full_uri);
    $mech->content_like($regexp_hr, "HTML description");
    $mech->content_unlike($regexp_en, "HTML description");

}

my $title = $site->titles->find({ uri => 'the-text', f_class => 'text' });
ok ($title, "Title found");
unlink $title->f_full_path_name or die $!;

$site->update_db_from_tree;

$title = $site->titles->find({ uri => 'the-text', f_class => 'text' });
ok (!$title, "Title was purged");

foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    ok ($cat, "Found " . $cat->full_uri);
    ok (!$cat->text_count, $cat->name . " should have 0 texts")
      or diag "But has " . $cat->text_count;
}


# then redo the same thing and check if the descs are still there

($revision) = $site->create_new_text({ uri => 'the-text',
                                       title => 'Hello',
                                       lang => 'hr',
                                       textbody => '',
                                     }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
$uri = $revision->publish_text;
ok $uri, "Found uri $uri";

foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    ok ($cat, "Found " . $cat->full_uri);
    ok ($cat->text_count, $cat->name . " should have 1 text")
      or diag "But has " . $cat->text_count;
    ok($cat->localized_desc('en'), "Description is there");
    ok($cat->localized_desc('hr'), "Description is there");
}

# $site->delete;

$mech->get_ok('/library/the-text');
$mech->content_contains('/category/author/pippo');
$mech->content_contains('/category/topic/the-cat');

foreach my $page ('/library/the-text', '/authors', '/topics',
                  '/authors/pippo', '/topics/the-cat') {
    $mech->get_ok($page);
    my $site_url = $site->canonical;
    my @links = grep { $_->url !~ /\Q$site_url\E\/(static|git|bookbuilder)/}
      $mech->find_all_links;
    $mech->links_ok(\@links);
    ok(scalar(@links), "Found and tested " . scalar(@links) . " links");
}
$mech->get('/bookbuilder');
is $mech->status, 401;

$mech->get_ok('/?__language=en');
$mech->get_ok('/authors/pippo');
$mech->content_lacks('amw-category-description-edit-button');
is $mech->uri->path, '/category/author/pippo', "Redirection ok";
$mech->get('/category/author/pippo/edit');
is $mech->status, 401, "Bounced to login";
$mech->content_contains('__auth_user');
$mech->content_lacks('__auth_human');
$mech->get('/category/author/pippo/delete');
is $mech->status, 401, "Bounced to login";
$mech->content_lacks('__auth_human');
ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
   "Found login form");
is $mech->uri->path, '/category/author/pippo/en/edit', "Redirection ok";

$mech->get_ok('/authors/pippo');
is $mech->uri->path, '/category/author/pippo', "Redirection ok";
$mech->content_contains('amw-category-description-edit-button');
$mech->get_ok('/category/author/pippo/edit');
is $mech->uri->path, '/category/author/pippo/en/edit', "Redirection ok";
$mech->content_like(qr{<h2>Update category description});
ok($mech->submit_form(with_fields => { desc_muse => "Pippo *is* a nice author" },
                      button => 'update'));
is $mech->uri->path, '/category/author/pippo/en', "Redirection ok";

is $site->categories->find({ uri => 'pippo', type => 'author' })
  ->category_descriptions->find({ lang => 'en' })->last_modified_by, "root",
  "last modified by root";


$mech->get_ok('/category/author/pippo');
$mech->content_contains('Pippo <em>is</em> a nice author');
$mech->content_like(qr{<li\s*class="active"\s*>\s*<a href=.*?/category/author/pippo">\s*All languages});
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_unlike(qr{<a href=.*?/category/author/pippo/it">\s*Italiano});

$mech->get_ok('/category/author/pippo?__language=it');
$mech->content_lacks('Pippo <em>is</em> a nice author', "No description, language changed");
$mech->content_like(qr{<li\s+class="active"\s*>\s*
                       <a\s+href=".*?/category/author/pippo">\s*
                       Tutte\s*le\s*lingue}x) or diag $mech->content;
$mech->content_unlike(qr{<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_like(qr{<a href=.*?/category/author/pippo/it">\s*Italiano});

$mech->get_ok('/category/author/pippo/en');
# we are in italian locale, but we get the description because of /en
$mech->content_contains('Pippo <em>is</em> a nice author');
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo">\s*Tutte le lingue});
$mech->content_like(qr{<li\s*class="active"\s*>\s*<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo/it">\s*Italiano});

$mech->get_ok('/category/author/pippo/en/edit');
$mech->content_contains('Pippo *is* a nice author'); # edit
$mech->content_contains('Pippo <em>is</em> a nice author'); # preview

$mech->get_ok('/category/author/pippo/edit');
is $mech->uri->path, '/category/author/pippo/it/edit', "Default edit goes into current lang";

$site->update({ multilanguage => '' });

$mech->get_ok('/category/author/pippo?__language=en');
$mech->content_contains('Pippo <em>is</em> a nice author');
$mech->content_contains('<meta name="description" content="Pippo is a nice author"');
$mech->content_unlike(qr{<a href=.*?/category/author/pippo">\s*Tutte le lingue});
$mech->content_unlike(qr{<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_unlike(qr{<a href=.*?/category/author/pippo/it">\s*Italiano});

$mech->get_ok('/category/author/pippo/edit');
is $mech->uri->path, '/category/author/pippo/en/edit', "Default edit goes into locale lang";

$mech->get_ok('/category/author/pippo/en');
$mech->content_contains('Pippo <em>is</em> a nice author');
$mech->content_contains('<meta name="description" content="Pippo is a nice author"');
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo">\s*All languages});
$mech->content_like(qr{<li\s*class="active"\s*>\s*<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_unlike(qr{<a href=.*?/category/author/pippo/it">\s*Italiano});
$mech->content_lacks('No text found!');

$mech->get_ok('/category/author/pippo/it');
$mech->content_lacks('Pippo <em>is</em> a nice author');
# here we inherited the english desc
$mech->content_contains('<meta name="description" content="Pippo is a nice author"');
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo">\s*All languages});
$mech->content_like(qr{<li\s*>\s*<a href=.*?/category/author/pippo/en">\s*English});
$mech->content_like(qr{<li\s*class="active"\s*>\s*<a href=.*?/category/author/pippo/it">\s*Italiano});
$mech->content_contains('No text found!');

$mech->get_ok("/category/author/pippo/en/edit");
$mech->content_contains("Pippo <em>is</em> a nice author");

$mech->get_ok("/logout");
$mech->get("/category/author/pippo/en/delete");
is $mech->status, 401, "Bounced to login";
ok($mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }),
   "Found login form");

$mech->get_ok("/category/author/pippo/en/delete");
is $mech->uri->path, "/category/author/pippo/en/edit";

ok $site->categories->find({ uri => 'pippo', type => 'author' })
  ->category_descriptions->find({ lang => 'en' }), "Found the desc";

$mech->submit_form(form_id => 'category-description-delete',
                   button => 'delete');
is $mech->uri->path, "/category/author/pippo/en", "Bounced ok";

ok !$site->categories->find({ uri => 'pippo', type => 'author' })
  ->category_descriptions->find({ lang => 'en' }), "Desc nuked";

ok $site->categories->find({ uri => 'pippo', type => 'author' }),
  "Category is still there";

