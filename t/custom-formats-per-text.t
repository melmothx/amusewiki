#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 30;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cformats1';
my $site = create_site($schema, $site_id);

$site->custom_formats->search({ bb_format => 'pdf' })->update({ active => 1 });
my $jolly = $site->custom_formats->create({
                                         format_name => "All",
                                         active => 0,
                                        });
my @revs;
foreach my $cf ($site->custom_formats->active_only) {
    ok $cf->active, $cf->extension . ' is active';
    diag $cf->bb_format;
    diag $cf->code;
    my $cf_code = $cf->code;
    my $in_all = $jolly->code;
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => "pallino $cf_code",
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    my $garbage = "a" x 1000;
    $rev->edit("#$garbage aa\n#formats $in_all $cf_code\n"
               . $rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    push @revs, $rev;
}

$jolly->update({ active => 1 });
$jolly->discard_changes;

my @texts;

foreach my $rev (@revs) {
    $rev->publish_text;
    push @texts, $rev->title->get_from_storage;
}

my $job_count = $site->jobs->pending->build_custom_format_jobs->count;
is $job_count, @revs * 2, "Got two jobs for each file";

foreach my $text (@texts) {
    ok $text->selected_formats;
    my $selected = $text->selected_formats;
    ok($selected, $text->uri . ' has selected formats') and diag Dumper($selected);
}

my @with_all;
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => "pallino all",
                                                lang => 'en',
                                              }, 'text');
    $rev->commit_version;
    $rev->publish_text;
    push @with_all, $rev->title->get_from_storage;
}

is $site->jobs->pending->build_custom_format_jobs->count, $job_count + 4,
  "Added 4 more job from  the one which does not select formats";

foreach my $text (@with_all) {
    ok !$text->selected_formats;
}

foreach my $i (@with_all, @texts) {
    ok $i->wants_custom_format($jolly);
}

$jolly->update({ active => 0 });

foreach my $cf ($site->custom_formats->active_only) {
    my $code = $cf->code;
    foreach my $i (@with_all) {
        ok $i->wants_custom_format($cf), $cf->code . ' is wanted by ' . $i->full_uri;
    }
    foreach my $i (@texts) {
        if ($i->uri =~ m/\Q$code\E/) {
            ok $i->wants_custom_format($cf), "$code wanted by " . $i->full_uri;
        }
        else {
            ok !$i->wants_custom_format($cf), "$code not wanted by " . $i->full_uri;
        }
    }
}

$site->jobs->delete;
$site->jobs->rebuild_add({ id => $with_all[0]->id })->dispatch_job;
is $site->jobs->pending->count, 4;
$site->jobs->delete;
$site->jobs->rebuild_add({ id => $texts[0]->id })->dispatch_job;
is $site->jobs->pending->count, 2;
$site->jobs->delete;
