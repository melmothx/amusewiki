#!perl

# This is probably a redundant test, but given that it's a delicate
# part of the code, better safe than sorry.
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;

use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Test::More tests => 9;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0fail0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });


MISSING_IMAGE: {
    my $url;
    my ($rev, $err) = $site->create_new_text({
                                              title => 'Failed',
                                              lang => 'en',
                                             }, 'text');
    $rev->edit(<<'MUSE');
#title Failed
#lang en

This will fail

[[xxxxx.jpg]]

[[xxxxx.png]]

MUSE

    $rev->commit_version;
    $rev->publish_text;
    my $url = $rev->title->full_uri;
    ok $url, "Target is $url";
    diag $rev->title->deleted;
    like $rev->title->deleted, qr{xxxx.*does not exist};
    $mech->get($url);
    is $mech->uri->path, "/console/unpublished";
    $mech->content_like(qr{xxxx.*does not exist});
}

DELETION: {
    my $url;
    my ($rev, $err) = $site->create_new_text({
                                              title => 'Deleted',
                                              lang => 'en',
                                             }, 'text');
    $rev->edit(<<'MUSE');
#title Failed
#lang en
#DELETED Do not <publish>

x
MUSE

    $rev->commit_version;
    $rev->publish_text;
    my $url = $rev->title->full_uri;
    ok $url, "Target is $url";
    diag $rev->title->deleted;
    $mech->get_ok("/console/unpublished?bare=1");
    $mech->content_contains('Do not &lt;publish&gt;', "Found escaped reason"); 
}


