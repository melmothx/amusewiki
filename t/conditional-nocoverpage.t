#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 28;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $init = catfile(qw/script jobber.pl/);
# kill the jobber if running
system($init, 'stop');


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0nofinal0';
my $site = create_site($schema, $site_id);
$site->update({
               secure_site => 0,
               tex => 1,
               pdf => 1,
              });

my ($with_toc, $no_toc);
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino no toc',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $no_toc = $rev->publish_text;
}
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino with toc',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n** Chapter\n\n some more text for the masses\n");
    $rev->commit_version;
    $with_toc = $rev->publish_text;
}
diag $with_toc;
diag $no_toc;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my %toc = (
           $with_toc => 1,
           $no_toc => 0,
          );

foreach my $uri (keys %toc) {
    $mech->get_ok($uri);
    $mech->get_ok($uri . '.pdf');
    $mech->get_ok($uri . '.tex');
    $mech->content_contains('{scrbook}');
    $mech->content_lacks('{scrartcl}');
    $mech->content_lacks('\let\chapter\section');
}

ok !$site->nocoverpage;

$mech->get('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get('/user/site');
$mech->submit_form(with_fields => { nocoverpage => 1 },
                   button => 'edit_site');

ok $site->discard_changes->nocoverpage, "Option picked up" or die;

# rebuild
foreach my $text ($site->titles) {
    $site->jobs->enqueue(rebuild => { id => $text->id }, 30);
 
}

while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
    is $job->status, 'completed';
}

foreach my $uri (keys %toc) {
    $mech->get_ok($uri);
    $mech->get_ok($uri . '.pdf');
    $mech->get_ok($uri . '.tex');
    # has toc?
    if ($toc{$uri}) {
        $mech->content_contains('{scrbook}');
        $mech->content_lacks('{scrartcl}');
        $mech->content_lacks('\let\chapter\section');
    }
    else {
        $mech->content_lacks('{scrbook}');
        $mech->content_contains('{scrartcl}');
        $mech->content_contains('\let\chapter\section');
    }
}
