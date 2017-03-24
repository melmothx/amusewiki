#!perl

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 63;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse qw/split_pdf/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $tmpdir = Path::Tiny->tempdir(CLEANUP => 0);
{
    my $file = path(qw/t files manual.pdf/);
    my @pdfs = split_pdf("$file", "$tmpdir");
    foreach my $pdf (@pdfs) {
        ok $pdf->exists, "$pdf exists";
    }
}
