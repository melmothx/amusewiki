#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 71;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $sid = '0sku0';
my $site = $schema->resultset('Site')->find($sid);
unless ($site) {
    $site = create_site($schema, $sid);
    $site->update({ secure_site => 0, epub => 1 });
    foreach my $prefix ('first', 'second') {
        foreach my $i (95..102) {
            my $sku = sprintf('%s-%.6d', $prefix, $i);
            foreach my $add_sku (0..1) {
                my ($rev) = $site->create_new_text({ title => "Prefix $i SKU $sku $add_sku",
                                                     textbody => ('<p>ciao</p>' x $i),
                                                     ($add_sku ? (cat => $prefix,
                                                                  author => $prefix) : ()),
                                                   }, 'text');
                $rev->edit("#sku   $sku   \n" . $rev->muse_body) if $add_sku;
                $rev->commit_version;
                $rev->publish_text;
            }
        }
    }
}
$site->site_options->delete;
ok $site->titles->search({ sku => '' })->count;
foreach my $text ($site->titles->search({ sku => { '!=' => '' } })) {
    ok $text->sku;
    diag $text->sku;
    like $text->sku, qr/\A[a-zA-Z0-9-]+\z/, "Sku stripped from trailing and leading whitespace";
}

is $site->titles->search({ sku => { "!=" => '' } })->order_by('sku_asc')->first->sku, 'first-000095';
is $site->titles->order_by('sku_desc')->first->sku, 'second-000102';

is $site->titles->order_by('pages_asc')->first->uri, 'prefix-95-sku-first-000095-0';
{
    my $page_desc = $site->titles->order_by('pages_desc');
    is $page_desc->next->uri, 'prefix-102-sku-first-000102-0';
    is $page_desc->next->uri, 'first-prefix-102-sku-first-000102-1';
}
{
    my $page_asc = $site->titles->order_by('pages_asc');
    is $page_asc->next->uri, 'prefix-95-sku-first-000095-0';
    is $page_asc->next->uri, 'first-prefix-95-sku-first-000095-1';
}



my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/login');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->content_contains('You are logged in now!');

diag "Checking if the option pops up";
$mech->get_ok('/category/author/first');
$mech->content_lacks('sku_desc');
$mech->content_lacks('sku_asc');

$mech->content_lacks('pages_desc');
$mech->content_lacks('pages_asc');


$mech->get_ok('/user/site');
$mech->content_lacks('sku_desc');
$mech->content_lacks('sku_asc');

$mech->content_lacks('pages_desc');
$mech->content_lacks('pages_asc');


$mech->submit_form(with_fields => {
                                   enable_order_by_sku => 1,
                                   show_type_and_number_of_pages => 1,
                                  },
                   button => 'edit_site');
$mech->get_ok('/user/site');
$mech->content_contains('sku_desc');
$mech->content_contains('sku_asc');

$mech->content_contains('pages_desc');
$mech->content_contains('pages_asc');


$mech->get_ok('/category/author/first');

$mech->content_contains('sku_desc');
$mech->content_contains('sku_asc');

$mech->content_contains('pages_desc');
$mech->content_contains('pages_asc');

foreach my $sorting ($site->discard_changes->titles_available_sortings) {
    $mech->get_ok('/listing?sort=' . $sorting->{name});
}

$site->site_options->update_or_create({
                                       option_name => 'titles_category_default_sorting',
                                       option_value => 'sku_asc',
                                      });

$site = $site->get_from_storage;

while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

foreach my $f (qw/titles.html topics.html authors.html/) {
    my $static = path($site->repo_root, $f)->slurp_utf8;
    like $static, qr{Prefix 95 SKU first-000095 1.*Prefix 97 SKU first-000097 1.*Prefix 102 SKU first-000102 1}s;
}

ok $site->enable_order_by_sku;
ok $site->validate_text_category_sorting('sku_asc') or die;
is $site->get_option('titles_category_default_sorting'), 'sku_asc' or die;
is $site->titles_category_default_sorting, 'sku_asc' or die;

my @tokens = $site->titles->published_texts
  ->static_index_tokens
  ->order_by($site->titles_category_default_sorting)
  ->all;

my @cats = $site->categories->by_type('topic')
  ->static_index_tokens
  ->order_titles_by($site->titles_category_default_sorting)
  ->all;

diag Dumper(\@tokens, \@cats);
