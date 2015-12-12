#!/bin/sh

set -e

texfontsdir=$HOME/texlive/2015/texmf-dist/fonts
if [ ! -d $texfontsdir ]; then
    texfontsdir=$HOME/texlive/2014/texmf-dist/fonts
fi
if [ ! -d $texfontsdir ]; then
    echo "Couldn't find $texfontsdir";
    exit 2;
fi

mkdir -p $HOME/.fonts
cd $HOME/.fonts
for font in 'CMU Serif'            \
            'Linux Libertine O'    \
            'Linux Biolinum O'     \
            'TeX Gyre Termes'      \
            'TeX Gyre Pagella'     \
            'TeX Gyre Schola'      \
            'TeX Gyre Bonum'       \
            'TeX Gyre Heros'       \
            'TeX Gyre Adventor'    \
            'TeX Gyre Cursor'      \
            'Charis SIL'           \
            'Antykwa Poltawskiego' \
            'Antykwa Torunska'     \
            'Iwona'                \
            'PT Serif'             \
            'PT Sans'              \
            'Droid Serif'          \
            'DejaVu Sans'          \
            'DejaVu Sans Mono'; do
    if fc-list "$font" | grep -q style; then
        echo "$font OK"
    else
        echo "$font NOT installed, installing"
        case "$font" in
            Linux*)
                rm -fv libertine
                ln -s $texfontsdir/opentype/public/libertine
                ;;
            TeX*)
                rm -fv tex-gyre
                ln -s $texfontsdir/opentype/public/tex-gyre
                ;;
            CMU*)
                rm -fv cm-unicode
                ln -s $texfontsdir/opentype/public/cm-unicode
                ;;
            *Torunska*)
                rm -fv antt
                ln -s $texfontsdir/opentype/public/antt
                ;;
            *Poltawskiego*)
                rm -fv poltawski
                ln -s $texfontsdir/opentype/gust/poltawski
                ;;
            PT*)
                rm -fv paratype
                ln -s $texfontsdir/truetype/paratype
                ;;
            Iwona*)
                rm -fv iwona
                ln -s $texfontsdir/opentype/nowacki/iwona
                ;;
            Droid*)
                rm -fv droid
                ln -s $texfontsdir/truetype/public/droid
                ;;
            DejaVu*)
                rm -fv dejavu
                ln -s $texfontsdir/truetype/public/dejavu
                ;;
            *Charis*)
                rm -fv charis
                wget -O $HOME/CharisSIL-4.114.zip 'http://scripts.sil.org/cms/scripts/render_download.php?format=file&media_id=CharisSIL-4.114.zip&filename=CharisSIL-4.114.zip'
                unzip -d $HOME/.fonts/charis $HOME/CharisSIL-4.114.zip
                ;;
            *)
                echo "Unhandled font $font!"
                ;;
        esac
        fc-cache -f
    fi
done
