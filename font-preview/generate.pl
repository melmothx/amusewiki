#!/usr/bin/env perl

use strict;
use warnings;
use Text::Amuse::Compile;
use Text::Amuse::Compile::Fonts;
use Data::Dumper;
use Path::Tiny;
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my ($file, $dest) = @ARGV;

die "Missing input file.json" unless ($file && -f $file);
die "Missing destination directory" unless ($dest && -d $dest);

my @fonts = Text::Amuse::Compile::Fonts->new($file)->all_fonts;

foreach my $ff (@fonts) {
    my $font = $ff->name;
    my $pdf = $font;
    $pdf =~ s/ /-/g;
    $pdf .= '.pdf';
    my $fdest = path($dest, $pdf);
    next if $fdest->exists;

    my $muse = 'font-preview.muse';
    if ($ff->has_languages) {
        foreach my $lang (@{ $ff->languages }) {
            if (-f "$lang.muse") {
                $muse = "$lang.muse";
                last;
            }
        }
    }
    my $muse_pdf = $muse;
    $muse_pdf =~ s/\.muse$/\.pdf/;

    my $c = Text::Amuse::Compile->new(
                                      pdf => 1,
                                      luatex => 1,
                                      fontspec => $file,
                                      cleanup => 1,
                                      extra => {
                                                papersize => 'a5',
                                                division => 15,
                                                sitename => $font,
                                                nocoverpage => 1,
                                                fontsize => 11,
                                                mainfont => $font,
                                                body_only => 1,
                                               },
                                     );
    $c->purge($muse);
    $c->compile($muse);
    my $png = "$fdest";
    $png =~ s/\.pdf$/.png/;
    system(qw/convert -density 150 -trim -quality 100 -sharpen 0x1.0/,  $muse_pdf . '[0]',  $png) == 0
      or die "Couldn't convert $pdf to $png $!";
    path($muse_pdf)->move("$fdest");
    $c->purge($muse);
    print "Generated $fdest\n";
}



