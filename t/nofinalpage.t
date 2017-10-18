#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 32;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0nofinal0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $rev->publish_text;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
$mech->get('/settings/formats');
is $mech->status, '401';
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
is $mech->status, '200';
ok $mech->submit_form(with_fields => {
                                      format_name => 'custom',
                                     });

my @fields = (qw/nofinalpage notoc nocoverpage unbranded/);
ok $mech->form_with_fields(@fields);

my $format = $site->custom_formats->first;
foreach my $f (@fields) {
    my $method = 'bb_' . $f;
    is $format->$method, 0, "$method is false";
}

foreach my $f (@fields) {
    $mech->tick($f => 1);
}
$mech->content_contains('Format successfully created');
$mech->click('update');
$mech->content_contains('Format successfully updated');

$format->discard_changes;
foreach my $f (@fields) {
    my $method = 'bb_' . $f;
    is $format->$method, 1, "$method is true";
}

$site->jobs->enqueue(rebuild => { id => $site->titles->first->id }, 15);
{
    my $produced;
    while (my $job = $site->jobs->dequeue) {
        $job->dispatch_job;
        is $job->status, 'completed';
        diag $job->logs;
        if ($job->task eq 'rebuild') {
            $produced = $job->produced;
        }
    }
    $mech->get_ok($produced . '.' . $format->extension);
    $mech->get_ok($produced);
}
ok $mech->follow_link( url_regex => qr{/bookbuilder/add/} );
$mech->get_ok('/bookbuilder');
ok $mech->form_with_fields(@fields);
foreach my $f (@fields) {
    $mech->tick($f => 1);
}
$mech->select(papersize => 'a6');
$mech->click('build');
{
    my $job = $site->jobs->dequeue;
    is $job->task, 'bookbuilder';
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
    $mech->get_ok($job->produced);
}

$mech->get_ok('/bookbuilder');
ok $mech->form_with_fields(@fields);
foreach my $f (@fields) {
    $mech->untick($f => 1);
}
$mech->select(papersize => 'a4');
$mech->click('build');
{
    my $job = $site->jobs->dequeue;
    is $job->task, 'bookbuilder';
    $job->dispatch_job;
    is $job->status, 'completed';
    diag $job->logs;
    $mech->get_ok($job->produced);
}
