#!perl
use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBI_TRACE} = 0;
};

use Data::Dumper;
use Test::More; # tests => 163;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(UTF-8)";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0prune0';
my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $type (qw/text special/) {
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         textbody => '<p>ciao</p>',
                                       }, $type);
    my $pdf = catfile(qw/t files shot.pdf/);
    my $got = $rev->add_attachment($pdf);
    for my $i (1..2) {
        $rev->add_attachment($pdf);
    }
    ok $got->{attachment};
    $rev->edit("#ATTACH $got->{attachment}\n" . $rev->muse_body);

    my $img = $rev->add_attachment(catfile(qw/t files shot.png/));
    $rev->edit($rev->muse_body . "\n\n[[$img->{attachment}]]\n");
    $rev->commit_version;
    $rev->publish_text;
    my $title = $rev->title->discard_changes;
    $mech->get_ok($title->full_uri);
    is $title->attachments->count, 2;
    foreach my $att ($title->attachments->all) {
        diag $att->uri;
    }
}

is $site->attachments->count, 8;
is $site->attachments->orphans->count, 4;
foreach my $att ($site->attachments->orphans) {
    diag $att->full_uri;
}

foreach my $text ($site->titles->all) {
    my $rev = $text->new_revision;
    $rev->edit("#title No attachment\n\nNo attachment");
    $rev->commit_version;
    sleep 1;
    $rev->publish_text;
}
foreach my $text ($site->titles->all) {
    is $text->attachments->count, 0;
}

is $site->attachments->count, 8;
is $site->attachments->orphans->count, 8;

done_testing;
