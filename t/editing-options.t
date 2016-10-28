#!perl

use strict;
use warnings;

use Test::More tests => 8;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0editingopts0');
my $user = $schema->resultset('User')->update_or_create({
                                                         username => 'u' . $site->id,
                                                         password => 'u' . $site->id,
                                                        });
my %defaults = (
                edit_option_preview_box_height =>  500,
                edit_option_show_filters =>  1,
                edit_option_show_cheatsheet =>  1,
                edit_option_page_left_bs_columns => 6,
               );
foreach my $method (keys %defaults) {
    is $site->$method, $defaults{$method}, "site.$method is fine";
    is $user->$method, $defaults{$method}, "user.$method is fine;"
}

# my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
#                                                host => $site->canonical);
# 
$user->delete;
