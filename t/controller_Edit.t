#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 125;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use HTML::Entities;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0edit1';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({ secure_site => 0 });
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);
$mech->get_ok('/?__language=en');
$mech->get('/action/text/new');
is $mech->status, 401;
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root'});
$mech->content_contains('You are logged in now!');

$mech->get_ok('/?__language=en');
$mech->get('/action/text/new');

diag "Uploading a text";
my $title = 'test-fixes';
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => $title,
                  textbody => "\n");

$mech->click;

$mech->content_contains('Created new text');

{
    my $editing_uri = $mech->uri;
    my $diff_uri = $mech->uri . '/diff';
    my $preview_uri = $mech->uri . '/preview';
    for my $admin ('/publish/pending', '/publish/all') {
        $mech->get_ok($admin);
        $mech->content_lacks('Show differences in other tab');
        $mech->content_contains('class="new-text-marker"');
    }
    $mech->get_ok($diff_uri);
    $mech->content_contains('No editing yet!');
    $mech->content_contains('This text is new');
    $mech->content_lacks('diff_match_patch.js');
    diag "Back to $editing_uri";
    $mech->get_ok($editing_uri);
    $mech->form_id('museform');
    $mech->field(body => "#title My *Title*\n#lang en");
    $mech->click('preview');
    $mech->content_contains('Show differences in other tab');

    $mech->get_ok($diff_uri);
    $mech->content_lacks('No editing yet!');
    $mech->content_contains('This text is new');
    $mech->content_contains('diff_match_patch.js');

    $mech->get_ok($preview_uri);
    $mech->content_contains("My <em>Title</em>");

    for my $admin ('/publish/pending', '/publish/all') {
        $mech->get_ok($admin);
        $mech->content_contains('Show differences in other tab');
        $mech->content_lacks('No editing yet!');
    }
    $mech->get_ok($editing_uri);
}


diag "In " . $mech->response->base->path;

$mech->form_id('museform');

my %expected = (
                en => q{“hello” <verbatim>[20]</verbatim>l’albero l’“adesso” <verbatim>"'</verbatim> ‘adesso’},
                fi => q{”hello” <verbatim>[20]</verbatim>l’albero l’”adesso” <verbatim>"'</verbatim> ’adesso’},
                it => q{“hello” <verbatim>[20]</verbatim>l’albero l’“adesso” <verbatim>"'</verbatim> ‘adesso’},
                hr => q{„hello” <verbatim>[20]</verbatim>l’albero l’„adesso” <verbatim>"'</verbatim> ‘adesso’},
                mk => q{„hello“ <verbatim>[20]</verbatim>l’albero l’„adesso“ <verbatim>"'</verbatim> ’adesso‘},
                sr => q{„hello“ <verbatim>[20]</verbatim>l’albero l’„adesso“ <verbatim>"'</verbatim> ’adesso’},
                es => q{«hello» <verbatim>[20]</verbatim>l’albero l’«adesso» <verbatim>"'</verbatim> ‘adesso’},
                ru => q{«hello» <verbatim>[20]</verbatim>l’albero l’«adesso» <verbatim>"'</verbatim> „adesso“},
               );

$mech->tick(fix_links => 1);
$mech->tick(fix_typography => 1);
$mech->tick(fix_footnotes => 1);
$mech->tick(fix_nbsp => 1);
$mech->tick(remove_nbsp => 1);

foreach my $lang (sort keys %expected) {
    my $body =<<"EOF";
#title $title
#lang $lang

"hello" <verbatim>[20]</verbatim>l'albero l'"adesso" <verbatim>"'</verbatim> 'adesso' [2]

[3] footnote http://amusewiki.org nbsp nbsp removed
EOF
    $mech->form_id('museform');
    # $body =~ s/\[20\]/\[20\]\0\r/sg;
    $mech->field(body => $body);
    $mech->click('preview');
    $mech->content_contains('&gt;[20]&lt;');
    $mech->form_id('museform');
    my $got_body = $mech->value('body');
    like $got_body, qr/\Q$expected{$lang}\E \[1\]/;
    $mech->content_contains(encode_entities($expected{$lang}, q{<>"}) .  ' [1]') or die $mech->content;
    my $exp_string =
      q{[1] footnote [[http://amusewiki.org][amusewiki.org]] nbsp nbsp removed};
    like $got_body, qr/\Q$exp_string\E/, "links, nbsp, footnotes fixed";
}

my $off_before =<<'EOF';
#title Title
#lang en

"hello" l'albero l'"adesso" 'adesso' [2] [3]

[3] footnote http://amusewiki.org nbsp nbsp removed
EOF

my $off_after =<<'EOF';
#title Title
#lang en

"hello" l'albero l'"adesso" 'adesso' [2] [3]

[3] footnote http://amusewiki.org nbsp nbsp removed

[4] footnote

[4] blablabla
EOF


foreach my $muse_body ($off_before, $off_after) {
    $mech->form_id('museform');
    $mech->untick(fix_links => 1);
    $mech->untick(fix_typography => 1);
    $mech->untick(fix_footnotes => 1);
    $mech->untick(fix_nbsp => 1);
    $mech->untick(remove_nbsp => 1);
    $mech->field(body => $muse_body);
    $mech->click('preview');
    $mech->form_id('museform');
    $mech->tick(fix_footnotes => 1);
    $mech->field(body => $muse_body);
    $mech->click('preview');
    $mech->form_id('museform');
    is $mech->value('body'), $muse_body, "Changes ignored";
    $mech->content_like(qr/Footnotes mismatch: found .+ footnotes .+ and found .+ footnote/);
}

diag "Testing the timestamp";
$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
my $date = '2014-11-11 11:11';
$mech->set_fields(title => "custom timestamp",
                  pubdate => $date);
$mech->click;
$mech->content_contains("#pubdate 2014-11-11") or diag $mech->content;

diag "Testing the js validation";
$mech->content_contains(q[name="message" class="form-control" required>]) or diag $mech->content;
my $editing = $mech->uri->path;
$mech->get_ok("/admin/sites/edit/$site_id/");
$mech->submit_form(with_fields => {
                                   do_not_enforce_commit_message => 'on',
                                  },
                   button => 'edit_site');
$mech->get_ok($editing);
$mech->content_contains(q[name="message" class="form-control" >]);

# $mech->get_ok('/action/text/new');

my $revision = $site->revisions->first;
$revision->commit_version;
$revision->publish_text;
my $text = $revision->title;
my $uri = $revision->title->full_uri;
$mech->get_ok($uri, "$uri is ok");
$mech->get_ok($uri . "/edit");
diag "Creating a revision";
diag $mech->uri;
my $edit_uri = $mech->uri->path;

diag "Try to create a new revision";
$mech->get_ok($uri . "/edit");
$mech->content_contains('at your own peril');
$mech->content_contains('This revision is being actively edited');
is ($text->revisions->not_published->count, 1,
    "Found the revision");
my $active = $text->revisions->not_published->first;

diag "Updating timestamp";
$active->update({ updated => DateTime->now->subtract(hours => 2) });
diag $active->id . " " . $active->updated;
$mech->get_ok($uri . "/edit");
is $mech->uri->path, $edit_uri,
  "One empty revision got redirected to the the original editing";
$mech->content_lacks('at your own peril');
$mech->content_lacks('Created new text');



diag "Updating timestamp";
$active->update({ updated => DateTime->now->subtract(minutes => 58) });
diag $active->id . " " . $active->updated;
$mech->get_ok($uri . "/edit");
diag $mech->uri;
$mech->content_contains('at your own peril');
$mech->content_contains('This revision is being actively edited');

# first we commit one
$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'porchetta',
                  title => 'formaggino',
                  textbody => "\nblabla\n");
$mech->click;
$mech->content_contains('Created new text') or die $mech->uri;
$mech->form_id('museform');
$mech->click('commit');

# then a new, uncommitted
$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => 'Going to abandon this',
                  textbody => "\n");
$mech->click;

$mech->content_contains('Created new text') or die $mech->uri;
$mech->get('/publish/pending');
$mech->content_like(qr{porchetta.*going-to-abandon-this}si, "First the committed, then the uncommitted");
$mech->get('/publish/all');
$mech->content_like(qr{porchetta.*going-to-abandon-this}si, "First the committed, then the uncommitted");

{
    $site->update({ mode => 'openwiki' });
    $mech->get_ok('/logout');
    $mech->get_ok('/action/text/new');
    ok($mech->form_id('ckform'), "Found the form for uploading stuff");
    $mech->set_fields(author => 'porchetta',
                      title => 'formaggino-xxx',
                      textbody => "\nblabla\n");
    $mech->click;
    $mech->content_contains('Created new text') or die $mech->uri;
    my ($rev_id) = $mech->uri =~ m/\/([0-9]+)$/;
    ok ($rev_id);
    $mech->form_id('museform');
    $mech->set_fields(username => "pal \rlino pin \0co");
    $mech->click('commit');
    my $revision = $site->revisions->find($rev_id);
    is $revision->username, 'pallinopinco.anon';
    like $revision->message, qr{\s+pallinopinco\s+}s;
}

{
    $site->update({ multilanguage => 'en it de',
                    blog_style => 1,
                  });
    $mech->get('/action/text/new');
    ok($mech->form_id('ckform'), "Found the form for uploading stuff");
    my %params = (
                  subtitle => "sottotitolo",
                  LISTtitle => "titolo listato",
                  author => "autore",
                  authors => "auth1, auth2",
                  topics => "topic1, topic2",
                  date => "2020 fall",
                  source => "My source",
                  uid => 'myuid1234',
                  lang => 'it',
                  textbody => '<p>Hello <em>world</em> <strong>asdf</strong></p>',
                  teaser => 'This is my teaser!',
                  notes => 'These are my notes',
                  pubdate => '2023-10-10',
                 );
    $mech->set_fields(%params);
    $mech->click;
    $params{title} = "Titolo";
    ok $mech->form_id('ckform');
    $mech->set_fields(title => $params{title});
    $mech->click;
    $mech->form_id('museform');
    my $muse_body = $mech->field('body');
    diag $muse_body;
    foreach my $k (keys %params) {
        if ($k eq 'textbody') {
            my $value = "\n\n\nHello <em>world</em> <strong>asdf</strong>\n\n\n";
            like $muse_body, qr{\Q$value\E}, "body ok";
        }
        elsif ($k eq 'pubdate') {
            my $value = substr($params{$k}, 0, 6);
            like $muse_body, qr{\#\Q$k\E \Q$value\E}, "$k is $value";
        }
        else {
            like $muse_body, qr{\#\Q$k\E \Q$params{$k}\E}, "$k ok";
        }
    }
    $mech->field(body => " #title test\nhello");
    $mech->click("commit");
    ok $mech->form_id('museform'), "Found the form";
    $mech->content_contains('Missing #title header in the text!');

    $mech->field(body => "#lang it\n #title test\nhello");
    $mech->click("commit");
    ok $mech->form_id('museform'), "Found the form";

    diag $mech->uri;

    $mech->content_contains('Missing #title header in the text!');
    $mech->field(body => "#lang it\n#title test\nhello");
    $mech->click("commit");

    is $mech->uri->path, "/publish/pending";
}
