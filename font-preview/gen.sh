#!/bin/bash

set -e

for font in 'CMU Serif'            \
            'Linux Libertine O'    \
            'TeX Gyre Termes'      \
            'TeX Gyre Pagella'     \
            'TeX Gyre Schola'      \
            'TeX Gyre Bonum'       \
            'Antykwa Poltawskiego' \
            'Antykwa Torunska'     \
            'Charis SIL'           \
            'PT Serif'             \
            'CMU Sans Serif'       \
            'TeX Gyre Heros'       \
            'TeX Gyre Adventor'    \
            'Iwona'                \
            'Linux Biolinum O'     \
            'DejaVu Sans'          \
            'PT Sans'              \
            'CMU Typewriter Text'  \
            'DejaVu Sans Mono'     \
            'TeX Gyre Cursor'; do
    muse-compile.pl --extra papersize=a5 --extra division=15 \
        --extra sitename="$font" \
        --extra nocoverpage=1 \
        --extra fontsize=11 --extra mainfont="$font" --pdf font-preview.muse
    pdf=$(echo $font | sed -e 's/ /-/g').pdf
    mv font-preview.pdf $pdf
    png=$(basename $pdf .pdf).png
    convert -density 150 -trim -quality 100 -sharpen 0x1.0 $pdf[1] $png
    mv $pdf $png ../root/static/images/font-preview
done
rm -f font-preview.aux font-preview.log font-preview.tex
