#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use Test::More tests => 4;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0year0');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

foreach my $uri (qw/f-f-first/) {
    my $file = path($site->repo_root, qw/f ff/, "$uri.muse");
    $file->parent->mkpath;
    my $muse = <<"MUSE";
#author <Author>
#topics <Topic>
#authors Author
#lang en
#date laskdf 2023
#datefirst lasdf 1932

MUSE
    $file->spew_utf8($muse);
}


$site->update_db_from_tree(sub { diag @_ });


my $title = $site->titles->first;
is $title->date, "laskdf 2023";
is $title->datefirst, "lasdf 1932";
is $title->date_year, 2023;
is $title->year_first_edition, 1932;
    
diag "TODO: document in the manual the #datefirst";

