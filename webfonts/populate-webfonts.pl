#!/usr/bin/env perl

use strict;
use warnings;
use IO::Pipe;
use File::Copy;
use File::Spec;
use Data::Dumper;
use File::Basename;

my @styles = (qw/bold italic regular bolditalic/);

my @fonts = ("Droid Serif",
             "Linux Libertine O",
             "PT Serif",
             "TeX Gyre Pagella",
             "Charis SIL",
            );

my %specs;

foreach my $font (@fonts) {
    my $pipe = IO::Pipe->new;
    $pipe->reader('fc-list', $font);
    $pipe->autoflush(1);
    while (<$pipe>) {
        chomp;
        if (m/(.+?)\s*:\s*(.+?)\s*:\s*style=(Bold|Italic|Regular|Bold Italic)$/) {
            my $file = $1;
            my $name = $2;
            my $style = lc($3);
            $style =~ s/\s//g;
            next unless $name eq $font;
            print "$file $name $style\n";
            if ($specs{$name}{$style}) {
                warn "Duplicated font! $file $name $style\n";
            }
            else {
                $specs{$name}{$style} = $file;
            }
        }
    }
}

print Dumper(\%specs);

FONT:
foreach my $font (keys %specs) {
    # check if we have all the for
    foreach my $need (@styles) {
        next FONT unless $specs{$font}{$need};
    }
    # write out and copy
    for my $dimension (qw/9 10/) {
        my $dirname = $font . $dimension;
        $dirname = lc($dirname);
        $dirname =~ s/\s+//g;
        mkdir $dirname unless -d $dirname;
        my $specfile = File::Spec->catfile($dirname, 'spec.txt');
        open (my $fh, '>', $specfile) or die "Cannot open $specfile $!";
        print $fh "family $font ${dimension}pt\nsize $dimension\n";
        foreach my $style (@styles) {
            print $fh $style . ' ' . basename($specs{$font}{$style}) . "\n";
            copy($specs{$font}{$style}, $dirname)
              or die "Cannot copy $specs{$font}{$style} to $dirname $!";
        }
        close $fh;
    }
}

