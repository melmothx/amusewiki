#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use FindBin qw/$Bin/;
use File::Basename;
use File::Find;
use File::Spec::Functions qw/catdir/;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Special;


binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $db = AmuseWikiFarm::Schema->connect('amuse');

foreach my $site (@ARGV) {
    my $site_schema = $db->resultset('Site')->find($site);
    die "Couldn't find $site!" unless $site_schema;
    my $arch = AmuseWikiFarm::Archive::Special->new(site_schema => $site_schema);
    my $target = $arch->muse_dir;
    mkdir $target unless -d $target;
    opendir (my $dh, $target) or die "Can't opendir $target $!";
    my @import = grep { /\w.*\.muse$/ && -f File::Spec->catfile($target, $_) }
      readdir ($dh);
    closedir $dh;
    foreach my $f (@import) {
        my $file = File::Spec->catfile($target, $f);
        $arch->import_file($file);
    }
}
