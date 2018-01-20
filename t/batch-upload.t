#!perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 34;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0edit2');
ok ($site);
$site->update({ secure_site => 0, mode => 'openwiki', magic_answer => 16, magic_question => '12+4' });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $mech_ext = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

$mech->get_ok('/');
$mech->get('/action/text/new');
is $mech->status, 401;
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root'});
$mech->content_contains('You are logged in now!');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => 'Test title',
                  textbody => "blablabla\n");

$mech->click;

$mech->content_contains('Created new text');
my $body = "#title My *Title*\n#lang en\n\nThis\n\nis\n\na\n\ntest\n";
$mech->submit_form(with_fields => {
                                   body => $body,
                                   attachment => catfile(qw/t files shot.png/),
                                   add_attachment_to_body => 0,
                                  },
                   button => 'preview');

is $site->revisions->first->muse_body, $body;
is $site->attachments->count, 1, "File uploaded";

{
    my $attachment = $site->attachments->first;
    diag $attachment->f_full_path_name;
    ok -f $attachment->f_full_path_name;
    like $attachment->f_full_path_name, qr{staging};
}

diag "Checking that other session can't stump on it";
$mech_ext->get_ok('/');
$mech_ext->get('/action/text/new');
is $mech_ext->status, 401;
$mech_ext->submit_form(with_fields => {
                                       __auth_human => '16',
                                      });
$mech_ext->get_ok($mech->uri);
$mech_ext->content_contains('This revision is being edited by someone else!');

$mech_ext->post($mech_ext->uri,
                Content_Type => 'form-data',
                Content => [
                            attachment => [ catfile(qw/t files shot.png/),
                                            catfile(qw/t files shot.png/),
                                            Content_Type => 'text/plain',
                                          ],
                            body => $body . ' balbalbal',
                            preview => 1,
                           ]);

$mech_ext->content_contains('This revision is being edited by someone else!');
my $rev = $site->revisions->first;
is $rev->muse_body, $body, "body not modified";
is $site->attachments->count, 1, "Only one file upload";

$rev->commit_version;
$rev->publish_text(sub { diag @_ });
$mech_ext->get_ok($mech->uri);
$mech_ext->content_contains('This revision is already published, ignoring changes');

$mech->get('/action/text/new');
$mech->submit_form(with_fields => {
                                   author => 'pippo',
                                   title => 'Test title 2',
                                   textbody => "blablabla\n"
                                  },
                   button => 'go');
$mech->content_contains('Created new text');

my $revedit =  $mech->uri;
$mech->post($revedit . '/upload',
            Content_Type => 'form-data',
            Content => [
                        attachment => [ catfile(qw/t files shot.png/),
                                        catfile(qw/t files shot.png/),
                                        Content_Type => 'image/png',
                                      ],
                       ]);
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok scalar(@{$res->{uris}});
}

$mech->post($revedit . '/upload',
            Content_Type => 'form-data',
            Content => [
                        attachment => [ catfile(qw/t files manual.pdf/),
                                        catfile(qw/t files manual.pdf/),
                                        Content_Type => 'application/pdf',
                                      ],
                       ]);
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok @{$res->{uris}} == 1;
}

$mech->get_ok($revedit . '/list-upload');
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok @{$res->{uris}} == 2;
}


$mech->post($revedit . '/upload',
            Content_Type => 'form-data',
            Content => [
                        split_pdf => 1,
                        attachment => [ catfile(qw/t files manual.pdf/),
                                        catfile(qw/t files manual.pdf/),
                                        Content_Type => 'application/pdf',
                                      ],
                       ]);
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok @{$res->{uris}} > 10;
}

$mech->get_ok($revedit . '/list-upload');
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok @{$res->{uris}} > 10;
}

$mech->get_ok('/api/lexicon.json');
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok $res->{MaxFileSizeError};
}

$mech->post($revedit . '/ajax',
            Content_Type => 'form-data',
            Content => [
                        fix_typography => 1,
                        body => qq{#title Hello there\n#lang en\n\n"hullo" "there"},
                        preview => 1,
                       ]);
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok $res->{body};
    like $res->{body}, qr/“hullo” “there”/;
}

$mech->post($revedit . '/ajax',
            Content_Type => 'form-data',
            Content => [
                        fix_typography => 1,
                        fix_footnotes => 1,
                        body => qq{#title Hello there\n#lang en\n\n"hullo" "there" [1]},
                        preview => 1,
                       ]);
{
    my $res = from_json($mech->content);
    diag $mech->content;
    ok !$res->{body};
    ok $res->{error}->{message};
}
