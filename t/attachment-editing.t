#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 6;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{AMW_NO_404_FALLBACK} = 1;
};

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
$site->update({ secure_site => 0, epub => 1 });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $attachment;
{
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         textbody => '<p>ciao</p>',
                                       }, 'text');
    my $pdf = catfile(qw/t files shot.pdf/);
    my $got = $rev->add_attachment($pdf);
    diag Dumper($got);
    ok $got->{attachment};
    $rev->edit("#ATTACH $got->{attachment}\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    $attachment = $got->{attachment};
}

$mech->get_ok('/');
$mech->get('/attachments');
is $mech->status, 401;
ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
$mech->get_ok('/attachments');
$mech->content_contains($attachment);
ok $mech->follow_link(url_regex => qr/attachments.*edit/);
