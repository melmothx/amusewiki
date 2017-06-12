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

my @fonts = sort map { $_->name } Text::Amuse::Compile::Fonts->new($file)->all_fonts;
print Dumper(\@fonts);

foreach my $font (@fonts) {
    my $pdf = $font;
    $pdf =~ s/ /-/g;
    $pdf .= '.pdf';
    my $fdest = path($dest, $pdf);
    next if $fdest->exists;
    my $c = Text::Amuse::Compile->new(
                                      pdf => 1,
                                      fontspec => $file,
                                      cleanup => 1,
                                      extra => {
                                                papersize => 'a5',
                                                division => 15,
                                                sitename => $font,
                                                nocoverpage => 1,
                                                fontsize => 11,
                                                mainfont => $font,
                                               },
                                     );
    $c->purge('font-preview.muse');
    $c->compile('font-preview.muse');
    my $png = "$fdest";
    $png =~ s/\.pdf$/.png/;
    system(qw/convert -density 150 -trim -quality 100 -sharpen 0x1.0/,  'font-preview.pdf[1]',  $png) == 0
      or die "Couldn't convert $pdf to $png $!";
    path('font-preview.pdf')->move("$fdest");
    $c->purge('font-preview.muse');
    print "Generated $fdest\n";
}



