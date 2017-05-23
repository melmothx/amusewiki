#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{DBIC_TRACE} = 1;
};

use utf8;
use strict;
use warnings;
use Test::More tests => 32;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use DateTime;
my $site_id = '0textrs0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site;
unless ($site = $schema->resultset('Site')->find($site_id)) {
    $site = create_site($schema, $site_id);
    foreach my $i (0..3) {
        my $defer = $i > 1 ? 1 : 0;
        my ($rev) = $site->create_new_text({ uri => ($defer ? 'deferred-' . $i : 'published-' . $i),
                                             title => ($defer ? 'Deferred #' . $i : 'Published #' . $i),
                                             teaser => ($i ? "This is the preview for $i" : ''),
                                             author => "Pallino",
                                             SORTtopics => "Topico",
                                             pubdate => ($defer ?
                                                         DateTime->now->add(days => 10)->ymd :
                                                         DateTime->today->ymd),
                                             lang => 'en' }, 'text');

        $rev->edit("#customheader xxx\n" . $rev->muse_body . "\n\nFULL TEXT HERE\n");
        $rev->commit_version;
        $rev->publish_text;
    }
}
{
    my @all = $site->titles->texts_only->published_all->all;
    is scalar(@all), 2, "published_all";
    is $all[0]->uri, 'published-0';
}
{
    my @all = $site->titles->texts_only->published_or_deferred_all->all;
    is scalar(@all), 4, "published_or_deferred_all";
    is $all[0]->uri, 'deferred-2';
}
{
    my @all = $site->titles->specials_only->published_or_deferred_all->all;
    is scalar(@all), 0, "specials only";
}

{
    my @all = $site->titles->status_is_published->order_by('title_asc')->rows_number(1)->page_number(2)->all;
    is scalar(@all), 1, "published";
    is $all[0]->uri, 'published-1';
}

{
    my @all = $site->titles->status_is_published_or_deferred
      ->order_by('title_asc')->rows_number(1)->page_number(2)->all;
    is scalar(@all), 1, "published or deferred";
    is $all[0]->uri, 'deferred-3';
}

{
    my @all = $site->titles->texts_only->status_is_published_or_deferred_with_teaser
      ->order_by('title_asc')->rows_number(1)->page_number(2)->all;
    is scalar(@all), 1, "published or deferred with teaser";
    is $all[0]->uri, 'deferred-3';
}

{
    my @all = $site->titles->specials_only->status_is_published_or_deferred_with_teaser
      ->newer_than(DateTime->new(year => 1980))
      ->order_by('title_asc')->rows_number(1)->page_number(1)->all;
    is scalar(@all), 0;
}

{
    my @all = $site->titles->texts_only->status_is_deferred->sorted_by_title;
    is scalar(@all), 2;
    is $all[0]->uri, 'deferred-2';
    is $all[1]->uri, 'deferred-3';    
}

{
    my @all = $site->titles->texts_only->status_is_deferred->sort_by_pubdate_desc;
    is scalar(@all), 2;
    is $all[0]->uri, 'deferred-2';
    is $all[1]->uri, 'deferred-3';    
}

{
    my @all = $site->titles->published_texts;
    is (scalar(@all), 2);
}

{
    my @all = $site->titles->published_or_deferred_texts;
    is (scalar(@all), 4);
}
{
    my @all = $site->titles->published_specials;
    is (scalar(@all), 0);
}
{
    my @all = $site->titles->published_or_deferred_specials;
    is (scalar(@all), 0);
}

{
    my $rand = $site->titles->random_text;
    ok $rand->uri;
    is $site->titles->text_by_uri($rand->uri)->uri, $rand->uri;
    is $site->titles->find_file($rand->f_full_path_name)->uri, $rand->uri;
}

{
    my @latest = $site->titles->latest(10);
    is scalar(@latest), 2;
}
{
    my @latest = $site->titles->latest(1);
    is scalar(@latest), 1;
}

{
    eval {
        my @latest = $site->titles->latest('asdfasdf');
    };
    ok $@, "Found exception $@";
}

{
    my @latest = $site->titles->unpublished;
    is scalar(@latest), 2;
}

{
    my @defer = $site->titles->deferred_to_publish(DateTime->now->add(years => 30));
    is scalar(@defer), 2;
}
{
    my @defer = $site->titles->older_than;
    is scalar(@defer), 2, 'older';
}
{
    my @defer = $site->titles->newer_than;
    is scalar(@defer), 2, 'newer';
}

