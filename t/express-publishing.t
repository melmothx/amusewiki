#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 28;
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

my $site = create_site($schema, '0revs0');
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$site->update({
               mode => 'openwiki',
               secure_site => 0,
              });
diag $site->mode;
is $site->sitegroup, '';
is $site->express_publishing, '';

foreach my $k (qw/id mode last_updated/) {
    eval {
        $site->update_option_value($k => 'asdfad');
    };
    ok $@, "$k is reserved";
}

$site->update_option_value(sitegroup => 'xxxx');
$site->update_option_value(express_publishing => 1);
$site = $site->get_from_storage;
is $site->sitegroup, 'xxxx';
is $site->express_publishing, 1;


# first, let's create a new text.
my $text;
{
    my $rev = $site->create_new_text({
                                      title => "Test",
                                      lang => 'en',
                                     }, 'text');
    $rev->commit_version;
    my $uri = $rev->publish_text;
    $text = $rev->title;
    $mech->get_ok($uri);
}
is $text->title, 'Test';
diag $text->muse_body;
is $text->revisions->count, 1;

$mech->get($text->full_edit_uri);
$mech->submit_form(with_fields => { __auth_human => '16' });

$site->jobs->delete;


$mech->submit_form(with_fields => {
                                   message => 'pippo',
                                   body => $text->muse_body . "\n\nciao ciao\n\n",
                                  },
                   button => 'commit',
                  );

# At this point the revision should be enqueued.

is $text->revisions->count, 2;
is $text->revisions->not_published->count, 1;
is $site->jobs->count, 1, "Job enqueued";
ok $text->revisions->not_published->first->only_one_pending;

if ($mech->uri->path =~ qr{/tasks/status/(\d+)}) {
    my $j = $site->jobs->find($1);
    ok $j, "Found job";
    ok $j->dispatch_job;
}
else {
    die "Express publishing not in effect";
}

$site->jobs->delete;

{
    $mech->get($text->full_edit_uri);
    $mech->submit_form(with_fields => {
                                       message => 'pippo',
                                       body => $text->muse_body . "\n\nciao ciao again\n\n",
                                      },
                       button => 'commit',
                      );
}

is $text->revisions->count, 3;
is $text->revisions->not_published->count, 1;
is $site->jobs->count, 1, "Job enqueued";
ok $text->revisions->not_published->first->only_one_pending;

if ($mech->uri->path =~ qr{/tasks/status/(\d+)}) {
    my $j = $site->jobs->find($1);
    ok $j, "Found job";
    ok $j->dispatch_job;
}
else {
    die "Express publishing not in effect";
}

$site->jobs->delete;


{
    $mech->get($text->full_edit_uri);

    # and spawn another one.
    $text->new_revision;

    $mech->submit_form(with_fields => {
                                       message => 'pippo',
                                       body => $text->muse_body . "\n\nciao ciao last\n\n",
                                      },
                       button => 'commit',
                      );
}

is $text->revisions->count, 5;
is $text->revisions->not_published->count, 2;
is $site->jobs->count, 0, "Job enqueued";
foreach my $rev ($text->revisions->not_published) {
    ok !$rev->only_one_pending;
}
is $mech->uri->path, '/publish/pending';
