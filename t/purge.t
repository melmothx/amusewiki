#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 9;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site run_all_jobs/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;

my $site_id = '0purge0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

{
    my $rev = $site->create_new_text({ uri => 'first-testx',
                                       title => 'Hello',
                                       lang => 'en',
                                       textbody => '<p>http://my.org My "precious"</p>',
                                     }, 'text');
    $rev->edit("#DELETED Test text purging\n" . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
}



my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');

$mech->get('/library/first-testx');
is $mech->status, 404;


$mech->get('/console/unpublished');
ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
$mech->content_contains('Test text purging');

$mech->get_ok('/library/first-testx');
is $mech->uri->path, ('/console/unpublished');

$mech->submit_form(form_name => 'purge');
my $status_page = $mech->uri;

diag "Page is $status_page";

my $j = $site->jobs->dequeue;
$j->dispatch_job;
is $j->produced, '/console/unpublished';
$mech->get_ok($status_page);
$mech->follow_link_ok({ text => 'Done'}, "Found /console/unpublished link");

                   
