#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 2;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0sku0');
$site->update({ secure_site => 0, epub => 1 });

foreach my $prefix ('first', 'second') {
    foreach my $i (95..102) {
        my $sku = sprintf('%s-%.6d', $prefix, $i);
        foreach my $add_sku (0..1) {
            my ($rev) = $site->create_new_text({ title => "SKU $sku $add_sku",
                                                 textbody => '<p>ciao</p>',
                                               }, 'text');
            $rev->edit("#sku $sku\n" . $rev->muse_body) if $add_sku;
            $rev->commit_version;
            $rev->publish_text;
        }
    }
}

ok $site->titles->search({ sku => '' })->count;
ok $site->titles->search({ sku => { '!=' => '' } })->count;
                         
