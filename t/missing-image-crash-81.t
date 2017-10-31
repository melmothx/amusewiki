#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use utf8;
use strict;
use warnings;
use Cwd;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 12;
use Data::Dumper;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::BookBuilder;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
my @uris = map { $_->uri } $site->titles->published_texts;
ok (scalar(@uris), "Found " . join(" ", @uris));
{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new;
    foreach my $uri (@uris, @uris) {
        $bb->add_text($uri);
    }
    my $cover = catfile(qw/t files shot.jpg/);
    ok( -f $cover, "Cover is here");
    $bb->add_file($cover);
    my @jobs;
    push @jobs, $site->jobs->bookbuilder_add($bb->serialize);
    $bb->add_file($cover);
    sleep 1;
    push @jobs, $site->jobs->bookbuilder_add($bb->serialize);
    foreach my $has_cover (0..1) {
        my $job = $jobs[$has_cover];
        $job->dispatch_job;
        is $job->status, 'completed';
        ok ($job->produced =~ m/([0-9]+\.pdf)\z/, "file is sane");
        ok (-f catfile(bbfiles => $1), "File $1 exists");
        ok $job->job_data->{coverfile}, "coverfile passed";
        if ($has_cover) {
            like $job->logs, qr{Using uploaded image on the};
        }
        else {
            like $job->logs, qr{Cover image provided vanished};
        }
        $job->delete;
    }
}
