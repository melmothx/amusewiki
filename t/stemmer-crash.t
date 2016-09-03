#!perl

use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Archive::Xapian;
use File::Temp;
use Test::More;

my $dir = File::Temp->newdir;
my @codes = (qw/da nl en fi fr de hu it no pt ro ru es sv tr dummy/);

plan tests => scalar(@codes);

foreach my $code (@codes) {
    my $xapian = AmuseWikiFarm::Archive::Xapian->new(code => $code,
                                                     locale => $code,
                                                     basedir => $dir->dirname);
    ok ($xapian->xapian_stemmer, "$code is ok");
}

