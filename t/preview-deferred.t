#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 303;
use Data::Dumper;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
# reuse the 
my $site_id = '0deferred1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0,
                epub => 1,
              });

ok !$site->show_preview_when_deferred;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
my (@urls, @covers, @teasers,
    @pub_urls, @pub_teasers, @pub_covers);
foreach my $i (0..3) {
    my $defer = $i > 1 ? 1 : 0;
    my ($rev) = $site->create_new_text({ uri => "deferred-text-$i",
                                         title => ($defer ? 'Deferred #' . $i : 'Published #' . $i),
                                         teaser => ($i ? "This is the preview for $i" : ''),
                                         author => "Pallino",
                                         SORTtopics => "Topico",
                                         pubdate => ($defer ? DateTime->now->add(days => 10)->ymd : DateTime->today->ymd),
                                         lang => 'en' }, 'text');
    my $cover = catfile(qw/t files shot.png/);
    if ($i) {
        my $got = $rev->add_attachment($cover);
        $rev->edit("#cover $got->{attachment}\n" . $rev->muse_body);
    }
    $rev->edit("#customheader xxx\n" . $rev->muse_body . "\n\nFULL TEXT HERE\n");
    $rev->commit_version;
    $rev->publish_text;
    if ($defer) {
        push @urls, $rev->title->full_uri;
        push @covers, $rev->title->cover if $rev->title->cover;
        push @teasers, $rev->title->teaser if $rev->title->teaser;
    }
    else {
        push @pub_urls, $rev->title->full_uri;
        push @pub_covers, $rev->title->cover  if $rev->title->cover;
        push @pub_teasers, $rev->title->teaser if $rev->title->teaser;
    }
}

$mech->get_ok('/api/autocompletion/topic');
$mech->content_contains('["Topico"]');
$mech->get_ok('/api/autocompletion/author');
$mech->content_contains('["Pallino"]');

foreach my $type (qw/author topic/) {
    my $rs = $site->categories->by_type($type)->with_texts(deferred => 1);
    my $cat = $rs->first;
    ok $cat, "Category $type found";
    is $cat->text_count, 4, "Text count is not stored";
    is ($schema->resultset('Category')->find($cat->id)->text_count, 0,
        "Category found from schema has no text_count");
}


foreach my $url (@urls) {
    diag $url;
    $mech->get($url);
    is $mech->status, 404;
}
foreach my $url (@pub_urls) {
    $mech->get_ok($url);
}

# attachments are always published even if the text is not
foreach my $att ($site->attachments->all) {
    $mech->get_ok($att->full_uri);
}

my @test_urls = (
                 '/category/topic/topico',
                 '/category/author/pallino'
                );

diag Dumper(\@pub_urls, \@pub_covers, \@pub_teasers);

foreach my $url (@test_urls) {
    diag "Getting $url";
    $mech->get($url);
    foreach my $fragment (@covers, @teasers, @urls) {
        $mech->content_lacks($fragment);
    }
    foreach my $fragment (@pub_covers, @pub_teasers, @pub_urls) {
        $mech->content_contains($fragment) or die $mech->content;
    }
}

$mech->get_ok('/login');
# foreach my $id (qw/amw-nav-bar-authors amw-nav-bar-topics/) {
#     $mech->content_lacks($id);
# }

ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
# we have published texts in those categories
# foreach my $id (qw/amw-nav-bar-authors amw-nav-bar-topics/) {
#     $mech->content_contains($id);
# }
$mech->content_contains('You are logged in now!');
foreach my $url (@urls, @pub_urls) {
    $mech->get_ok($url);
    $mech->content_contains("FULL TEXT HERE");
}

foreach my $url (@test_urls) {
    $mech->get_ok($url);
    foreach my $fragment (@covers, @teasers, @urls, @pub_covers, @pub_teasers, @pub_urls) {
        $mech->content_contains($fragment);
    }
}

$mech->get_ok('/logout');
$site->add_to_site_options({
                             option_name => 'show_preview_when_deferred',
                             option_value => 1,
                            });
$site = $schema->resultset('Site')->find($site->id);

ok $site->show_preview_when_deferred;

foreach my $url (@test_urls) {
    $mech->get_ok($url);
    foreach my $fragment (@covers, @teasers, @pub_urls, @pub_covers, @pub_teasers) {
        $mech->content_contains($fragment);
    }
    foreach my $fragment (@urls) {
        $mech->content_contains($fragment);
    }
}
foreach my $url (@urls) {
    $mech->get_ok($url);
    $mech->content_contains('<div class="alert alert-warning" role="alert">This text is not available</div>',
                            "$url is without body not accessible");
    $mech->content_lacks("FULL TEXT HERE");
}

for (1..3) {
    $mech->get_ok('/search?query=pallino&fmt=json');
    my $search_results = from_json($mech->content);
    is (scalar(@$search_results), 2) or diag Dumper($search_results);
}

ok ($site->xapian->index_deferred, "Xapian will index the deferred as well") or die;
$site->xapian_reindex_all;

for (1..3) {
    # after reindexing (option is on now), we have 4 results
    $mech->get_ok('/search?query=pallino&fmt=json');
    foreach my $url (@urls, @pub_urls) {
        $mech->content_contains($url);
    }
    my $search_results = from_json($mech->content);
    is (scalar(@$search_results), 4) or diag Dumper($search_results);
}

my @exts = ('.zip', '.html', '.epub', '.tex', '.muse');
# note that if you have public git, the text will be exposed anyway

foreach my $url (@pub_urls) {
    $mech->get_ok($url);
    $mech->content_lacks('<div class="alert alert-warning" role="alert">This text is not available</div>',
                            "$url is without body not accessible");
    $mech->content_contains("FULL TEXT HERE");
    foreach my $ext (@exts) {
        $mech->get_ok($url . $ext);
    }
}
foreach my $url (@urls) {
    foreach my $ext (@exts) {
        $mech->get($url . $ext);
        is $mech->status, 404, "$url$ext is 404";
    }
}
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

foreach my $url (@urls, @pub_urls) {
    foreach my $ext (@exts) {
        $mech->get_ok($url . $ext);       
        diag $mech->response->header('Content-Type');
    }
}

# and now the bookbuilder
$mech->get_ok('/logout');
for my $i (0..1) {
    $mech->get_ok("/bookbuilder/add/deferred-text-$i");
    $mech->content_contains('The text was added to the bookbuilder');
    $mech->get_ok("/bookbuilder");
}
for my $i (2..3) {
    $mech->get_ok("/bookbuilder/add/deferred-text-$i");
    $mech->content_lacks('The text was added to the bookbuilder');
}
$mech->get_ok('/bookbuilder');
foreach my $url (@urls) {
    $mech->content_lacks($url);
}
foreach my $url (@pub_urls) {
    $mech->content_contains($url);
}

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

# add the missing one
for my $i (2..3) {
    $mech->get_ok("/bookbuilder/add/deferred-text-$i");
    $mech->content_contains('The text was added to the bookbuilder');
}

$mech->get_ok('/bookbuilder');
foreach my $url (@urls, @pub_urls) {
    $mech->content_contains($url);
}

$mech->submit_form(with_fields => { title => 'Blabla' },
                   button => 'build');

my $job = $site->jobs->dequeue->dispatch_job;
my $j_url = $job->produced;
my $c_url = '/tasks/status/' . $job->id;
diag "Got $j_url";
$mech->get_ok($j_url);
$mech->get_ok($c_url);

# logout and recheck
$mech->get_ok('/logout');

$mech->get($j_url);
is $mech->status, 404;
$mech->get($c_url);
is $mech->status, 404;

# now the deferred titles are gone
$mech->get_ok('/bookbuilder');
foreach my $url (@pub_urls) {
    $mech->content_contains($url);
}
foreach my $url (@urls) {
    $mech->content_lacks($url);
}

foreach my $url (@urls, @pub_urls) {
    $mech->get_ok($url);
    my $full = $mech->uri;
    $mech->content_contains(qq{id="page" data-text-json-header-api="$full/json">});
    $mech->get_ok($url . '/json');
    my $hashref = from_json($mech->content);
    diag Dumper($hashref);
    is $hashref->{customheader}, 'xxx';
    is $hashref->{lang}, 'en';
}

$site->site_options->update_or_create({
                                       option_name => 'show_preview_when_deferred',
                                       option_value => 0,
                                      });

foreach my $url (@urls) {
    $mech->get($url . '/json');
    is $mech->status, 404;
}
foreach my $url (@pub_urls) {
    $mech->get_ok($url . '/json');
}

$mech->get_ok('/latest');
foreach my $url (@urls) {
    $mech->content_lacks($url);
}
foreach my $url (@pub_urls) {
    $mech->content_contains($url);
}

$site->site_options->update_or_create({
                                       option_name => 'show_preview_when_deferred',
                                       option_value => 1,
                                      });

foreach my $page ('/library', '/category/author/pallino', '/category/topic/topico') {
    $mech->get_ok($page);
    $mech->content_contains('deferred-text-3');
    $mech->content_contains('deferred-text-2');
}

$site->titles->find({ uri => 'deferred-text-2',
                      f_class => 'text' })->update({ teaser => '' });

foreach my $page ('/library', '/category/author/pallino', '/category/topic/topico') {
    $mech->get_ok($page);
    $mech->content_contains('deferred-text-3');
    $mech->content_lacks('deferred-text-2');
}

# login
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

foreach my $page ('/library', '/category/author/pallino', '/category/topic/topico') {
    $mech->get_ok($page);
    $mech->content_contains('deferred-text-3');
    $mech->content_contains('deferred-text-2');
}

for (1..3) {
    $mech->get_ok('/search?query=pallino&fmt=json');
    foreach my $url ('deferred-text-3', @pub_urls) {
        $mech->content_contains($url);
    }
    $mech->content_lacks('deferred-2');
    my $search_results = from_json($mech->content);
    is (scalar(@$search_results), 3) or diag Dumper($search_results);
}

$site->site_options->update_or_create({
                                       option_name => 'show_preview_when_deferred',
                                       option_value => 0,
                                      });

for (1..3) {
    $mech->get_ok('/search?query=pallino&fmt=json');
    foreach my $url (@pub_urls) {
        $mech->content_contains($url);
    }
    foreach my $url (@urls) {
        $mech->content_lacks($url);
    }
    my $search_results = from_json($mech->content);
    is (scalar(@$search_results), 2) or diag Dumper($search_results);
}

$site->site_options->update_or_create({
                                       option_name => 'show_preview_when_deferred',
                                       option_value => 1,
                                      });
$site->xapian_reindex_all;
