#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use DateTime;
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0sorting0');

my $predate = DateTime->now;
sleep 1;
my $date = DateTime->now;
sleep 1;
my $postdate = DateTime->now;

for my $num (10..40) {
    my $pubdate = $date;
    if ($num < 15) {
        $pubdate = $predate;
    }
    elsif ($num > 35) {
        $pubdate = $postdate;
    }
    $site->add_to_titles({
                          title => "$num title",
                          f_class => "text",
                          pubdate => $pubdate,
                          uri => "$num-title",
                          status => "published",
                          f_path => "dummy",
                          f_name => "$num-title.muse",
                          f_archive_rel_path => "",
                          f_timestamp => $date->epoch,
                          f_full_path_name => '',
                          f_suffix => ".muse",
                          sorting_pos => $num,
                         });
}

is $site->titles->count, 31;
my %all;
{
    my @recs = $site->titles->published_texts->sort_by_pubdate_desc;
    is $recs[0]->uri, "36-title";
    is $recs[30]->uri, "14-title";
    is $recs[0]->newer_text, undef;
    is $recs[0]->older_text->uri, "15-title";
    is $recs[0]->older_text->older_text->uri, "10-title";
    is $recs[30]->older_text, undef;
    is $recs[30]->newer_text->uri, "15-title";
    is $recs[30]->newer_text->newer_text->uri, "36-title";
    %all = map { $_->uri => 1 } @recs;
}

for my $page (1..4) {
    my $recs = $site->titles->published_texts->sort_by_pubdate_desc
      ->search(undef, { rows => 10, page => $page });
    diag "Page $page:";
    while (my $text = $recs->next) {
        diag $text->uri;
        delete $all{$text->uri};
    }
}

ok (!%all, "All texts found in pagination");
