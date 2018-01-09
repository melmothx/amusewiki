#!perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 20;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

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
is $site->revisions->first->muse_body, $body, "body not modified";
is $site->attachments->count, 1, "Only one file upload";
