#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::More tests => 29;
use Data::Dumper;
use Path::Tiny;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
# reuse the 
my $site_id = '0deferred1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
my (@urls, @covers, @teasers);
foreach my $i (1..2) {
    my ($rev) = $site->create_new_text({ uri => "deferred-text-$i",
                                         title => 'Deferred #' . $i,
                                         teaser => "This is the preview for $i",
                                         author => "Pallino",
                                         topics => "Topico",
                                         pubdate => DateTime->now->add(days => 10)->ymd,
                                         lang => 'en' }, 'text');
    my $cover = catfile(qw/t files shot.png/);
    my $got = $rev->add_attachment($cover);
    $rev->edit("#cover $got->{attachment}\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
    push @urls, $rev->title->full_uri;
    push @teasers, $rev->title->teaser;
    push @covers, $rev->title->cover;
}

foreach my $url (@urls) {
    diag $url;
    $mech->get($url);
    is $mech->status, 404;
}
foreach my $att ($site->attachments->all) {
    $mech->get_ok($att->full_uri);
}
$mech->get_ok('/login');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->content_contains('You are logged in now!');
foreach my $url (@urls) {
    diag $url;
    $mech->get_ok($url);
}

foreach my $url (
                 '/latest',
                 '/category/topics/topico',
                 '/category/authors/pallino') {
    $mech->get_ok($url);
    foreach my $fragment (@covers, @teasers) {
        $mech->content_contains($fragment);
    }
}

