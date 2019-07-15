#!perl
use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Test::More tests => 283;
use Data::Dumper::Concise;
use YAML qw/Dump Load/;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0blobs0');

$site->site_options->update_or_create({ option_name => 'show_type_and_number_of_pages',
                                        option_value => 1 });

foreach my $f (path('t/binary-files')->children) {
    diag "Copying $f to uploads directory";
    $f->copy($site->path_for_uploads);
}


my %expected = (
                flac => 'audio/flac',
                mp3 => 'audio/mpeg',
                ogg  => 'audio/x-vorbis+ogg',
                avi => 'video/x-msvideo',
                mkv => 'video/x-matroska',
                mov => 'video/quicktime',
                mp4 => 'video/mp4',
                mpg => 'video/mpeg',
                ogv => 'video/x-theora+ogg',
                webm => 'video/webm',
                pdf => 'application/pdf',
                epub => 'application/epub+zip',
               );

my @files;
foreach my $f (sort (path($site->path_for_uploads)->children)) {
    my $mime = AmuseWikiFarm::Utils::Amuse::mimetype("$f");
    if ($f =~ m/\.(\w+)$/) {
        my $ext = $1;
        is $mime, $expected{$ext}, "$f mimetype correct: $mime";
        push @files, $f->basename;
    }
    else {
        die "Bad filename"
    }
}

# then create a file

my $muse = path($site->repo_root, qw/t tt test.muse/);
$muse->parent->mkpath;
$muse->spew_utf8(<<"MUSE");
#title File Gallery
#attach @{[ join(' ', @files) ]}

MUSE

ok $muse->exists, "$muse is fine";

$site->update_db_from_tree(sub { diag join(' ', @_) });

is $site->attachments->count, scalar(@files);
is $site->titles->count, 1;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get_ok('/latest');
$mech->content_lacks('This text is a book');
$mech->content_contains('This text is an article');
$mech->content_contains('amw-show-text-type');
$mech->content_contains('amw-show-text-type-and-number-of-pages');


sleep 1;

$muse->spew_utf8(<<"MUSE");
#title File Gallery
#blob ocr
#attach @{[ join(' ', @files) ]}

This is the beginning of the OCR

Bla bla bla

MUSE

path($site->repo_root, qw/uploads test.exe/)->spew_utf8("#!/bin/bash\n\necho ciao\n");

$site->update_db_from_tree(sub { diag join(' ', @_) });

foreach my $f (@files) {
    ok $site->attachments->find({ uri => $f });
    $mech->get_ok("/uploads/" . $site->id . "/" . $f);
}
# however, it's impossible to download
ok $site->attachments->find({ uri => 'test.exe' });
my $res = $mech->get("/uploads/" . $site->id . "/test.exe");
is $res->code, 403;

$mech->get_ok('/latest');
$mech->content_lacks('This text is a book');
$mech->content_lacks('This text is an article');
$mech->content_lacks('amw-show-text-type');
$mech->content_lacks('amw-show-text-type-and-number-of-pages');

$site->site_options->update_or_create({ option_name => 'allow_binary_uploads',
                                        option_value => 0 });
$site->discard_changes;
foreach my $type (qw/text special/) {
    my ($rev) = $site->create_new_text({ title => "Add $type",
                                         lang => 'en',
                                         textbody => 'ciao',
                                       }, $type);
    foreach my $f (path('t/binary-files')->children) {
        my $outcome = $rev->add_attachment("$f");
        next if $f =~ m/\.pdf$/;
        ok $outcome->{error} or die Dumper($outcome);
    }
    $rev->commit_version;
    $rev->publish_text;
}

$site->site_options->update_or_create({ option_name => 'allow_binary_uploads',
                                        option_value => 1 });

my @check;

$site->discard_changes;
foreach my $type (qw/text special/) {
    my ($rev) = $site->create_new_text({ title => "Add 1 $type",
                                         lang => 'en',
                                         textbody => 'ciao',
                                       }, $type);
    foreach my $f (path('t/binary-files')->children) {
        my $outcome = $rev->add_attachment("$f");
        ok !$outcome->{error} or die Dumper($outcome);
        push @check, $outcome->{attachment};
    }
    $rev->edit("#blob 1\n#attach " . join(' ', @check) . "\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text(sub { diag @_ });
    $mech->get_ok($rev->title->full_uri);
    foreach my $uri (@check) {
        $mech->content_contains($uri);
    }
}

foreach my $uri (@check) {
    my $att = $site->attachments->find({ uri => $uri });
    unlike $att->f_full_path_name, qr{staging/\d+/blobs};
    my $path = $site->path_for_uploads;
    like $att->f_full_path_name, qr{\Q$path/$uri\E};
    $mech->get_ok($att->full_uri);
    my @logs = $site->git->log($att->f_full_path_name);
    ok (@logs) and diag $att->f_full_path_name . " => " . $logs[0]->id;    
}

# now see how it works with the browsers
{

    my $count = $site->attachments->count;
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
    my $binfile = catfile(qw/t binary-files video.mp4/);

    my $edit_url = $mech->uri;
    foreach my $embed (0, 1) {
        $mech->get_ok($edit_url);
        $mech->submit_form(with_fields => {
                                           body => $body,
                                           attachment => $binfile,
                                           add_attachment_to_body => 0,
                                          },
                           button => 'preview');
        $count++;
        is $site->attachments->count, $count, "File uploaded";
    }

    foreach my $embed (0, 1) {
        $mech->post($edit_url . '/upload',
                    Content_Type => 'form-data',
                    Content => [
                                attachment => [
                                               $binfile,
                                               $binfile,
                                               Content_Type => 'image/png',
                                              ],
                               ]);
        $count++;
        is $site->attachments->count, $count, "File uploaded";
    }
    $mech->get_ok($edit_url);
    $mech->form_id('museform');
    $mech->click('commit');
    foreach my $i (1..4) {
        $mech->content_contains ("p-t-pippo-test-title-$i.mp4");
    }
    $mech->get_ok('/logout');
    
    $site->update({ mode => 'modwiki' });

    $mech->get('/action/text/new');
    ok($mech->form_id('ckform'), "Found the form for uploading stuff");
    $mech->set_fields(author => 'pippo 2',
                      title => 'Test title 2',
                      textbody => "blablabla\n");
    $mech->click;
    $mech->content_contains('Created new text');

    $edit_url = $mech->uri;
    foreach my $embed (0, 1) {
        $mech->get_ok($edit_url);
        $mech->submit_form(with_fields => {
                                           body => $body,
                                           attachment => $binfile,
                                           add_attachment_to_body => 0,
                                          },
                           button => 'preview');
        is $site->attachments->count, $count, "File NOT not uploaded";
    }

    foreach my $embed (0, 1) {
        $mech->post($edit_url . '/upload',
                    Content_Type => 'form-data',
                    Content => [
                                attachment => [
                                               $binfile,
                                               $binfile,
                                               Content_Type => 'image/png',
                                              ],
                               ]);
        is $site->attachments->count, $count, "File NOT uploaded";
    }
}

# deletions
{
    my ($rev) = $site->create_new_text({ title => "Add and delete",
                                         lang => 'en',
                                         textbody => 'ciao',
                                       }, 'text');
    my @discard;
    foreach my $f (path('t/binary-files')->children) {
        my $outcome = $rev->add_attachment("$f");
        ok $outcome->{attachment};
        push @discard, $outcome->{attachment};
    }
    foreach my $u (@discard) {
        my $res = $rev->remove_attachment($u);
        ok $res->{success};
    }
    ok scalar($rev->all_attachments) == 0;
}
