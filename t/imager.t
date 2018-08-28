#!perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Imager;
use Data::Dumper::Concise;
use Test::More tests => 53;
use AmuseWikiFarm::Utils::Amuse qw/split_pdf image_dimensions/;
use AmuseWikiFarm::Schema;
use Path::Tiny;

ok $Imager::formats{png}, "PNG supported";
ok $Imager::formats{jpeg}, "JPEG supported";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

{
    $site->index_site_files;
    my $file = $site->site_files->search({ file_name => 'navlogo.png' })->first;
    ok $file->image_width, "width ok" and diag $file->image_width;
    ok $file->image_height, "height ok" and diag $file->image_height;
}

{
    my ($w, $h) = image_dimensions(path(qw/t files shot.jpg/));
    is $w, 350;
    is $h, 445;
}
{
    my ($w, $h) = image_dimensions(path(qw/t files shot.jpg/));
    is $w, 350;
    is $h, 445;
}

{
    my ($w, $h) = image_dimensions(path(qw/t files doesnotexists.jpg/));
    is $w, undef;
    is $h, undef;
}

{
    my $tmp = Path::Tiny->tempdir(CLEANUP => 1);
    my @images = split_pdf(path(qw/t files amw-version-22.pdf/), $tmp);
    ok @images;
    foreach my $i (@images) {
        ok $i->exists;
    }
    diag Dumper(\@images);
}

{
    my $tmp = Path::Tiny->tempdir(CLEANUP => 1);
    foreach my $src (path(qw/t files amw-version-22.pdf/),
                     path(qw/t files shot.jpg/),
                     path(qw/t files shot.png/)) {
        foreach my $w (36, 150, 300) {
            my $out = $tmp->child($src->basename . '.' . $w . '.png');
            my ($width, $height) = AmuseWikiFarm::Utils::Amuse::create_thumbnail($src, $out, $w);
            diag "Generated $out from $src with $w: $width $height";
            ok $width;
            ok $height;
            is $width, $w, "$src width is $width";
            ok -f $out;
        }
    }
}

1;
