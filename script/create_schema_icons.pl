#!/usr/bin/env perl

use strict;
use warnings;
use PDF::Imposition;
use PDF::API2;
use Path::Tiny;

my $hor = [
           {
            icon => 'horizontal.png',
            position => '+240+215',
           },
          ];

my %schemas = (
               '2up' => { pages => 8, final => 4, },
               '2down' => { pages => 8, final => 4 },
               '2side' => { pages => 8, final => 4 },
               '2x4x1' => { pages => 8, final => 2,
                            scissors => $hor,
                          },
               '2x4x2' => {
                           pages => 16, final => 4,
                           scissors => $hor,
                          },
               '1x4x2cutfoldbind' => {
                                      pages => 8, final => 2,
                                      scissors => $hor,
                                     },
               '4up' => {
                         pages => 16, final => 4,
                         scissors => $hor,
                        },
               'ea4x4' => { pages => 16, final => 4, scissors => $hor },
               '1x8x2' => { pages => 16, final => 2,
                            scissors => [ {
                                           icon => 'horizontal.png',
                                           position => '+240+215',
                                          },
                                          {
                                           icon => 'vertical.png',
                                           position => '+295+80',
                                          }
                                        ],
                          },
               '1x1' => { pages => 2, final => 2 },               
              );

my $target = path("root/static/images/schema-preview");
my $wd = path("/tmp/schemas");
$wd->mkpath;
print "Using $wd\n";

foreach my $schema (keys %schemas) {
    my $file = path($wd, $schema . '-in.pdf');
    my $pdf = PDF::API2->new();
    $pdf->mediabox(80, 120);
    my $font = $pdf->corefont('Helvetica');
    foreach my $p (1 .. $schemas{$schema}{pages}) {
        my $page = $pdf->page();
        my $text = $page->text();
        $text->font($font, 48);
        $text->translate(40, 50);
        $text->text_center($p, -underline => 'auto');
        my $line = $page->gfx;
        $line->linewidth(4);
        $line->strokecolor('black');
        $line->rectxy(0, 0, 80, 120);
        $line->stroke;
    }
    $pdf->saveas("$file");
    my $imposed = path($wd, $schema . '-imp.pdf');
    PDF::Imposition->new(file => "$file",
                         outfile => "$imposed",
                         schema => $schema)->impose;

    foreach my $final (1 .. $schemas{$schema}{final}) {
        my $out = $target->child("schema-${schema}-${final}.png");
        render_png($imposed, $final, $out, $schemas{$schema}{scissors});
        print "Output in $out\n";
    }
    
}

sub render_png {
    my ($pdf, $page, $out, $scissors) = @_;
    system(gs => '-sDEVICE=png16m', '-dTextAlphaBits=4', "-q",
           "-dFirstPage=$page", "-dLastPage=$page",
           "-r144",
           "-o", "$out", "$pdf");
    die "$out not produced" unless -f $out;
    foreach my $scissor (@{$scissors || []}) {
        my $icon = $target->child($scissor->{icon});
        die "$icon doesn't exist" unless $icon->exists;
        system(gm => composite => -geometry => $scissor->{position},
               "$icon",
               "$out",
               "$out-work");
        path("$out-work")->move($out);
    }
}
