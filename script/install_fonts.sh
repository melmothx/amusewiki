#!/bin/sh

set -e

echo "Checking and installing missing fonts"

linkfont () {
    rm -fv `basename $1`
    for texfontsdir in "$HOME/texlive/2017/texmf-dist/fonts" \
                       "$HOME/texlive/2016/texmf-dist/fonts" \
                       "$HOME/texlive/2015/texmf-dist/fonts" \
                       "$HOME/texlive/2014/texmf-dist/fonts" \
                       "/usr/local/share/texmf-dist/fonts" \
                       "/usr/share/texmf/fonts" \
                       "/usr/share/texlive/texmf-dist/fonts"; do
        if [ -d "$texfontsdir/$1" ]; then
            ln -s "$texfontsdir/$1"
            return 0
        fi
    done
    return 0
}

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
            'Noto Sans' \
            'Noto Serif' \
            'DejaVu Sans'          \
            'DejaVu Sans Mono'; do
    if fc-list "$font" | grep -q style; then
        echo "$font OK"
    else
        echo "$font NOT installed, installing"
        case "$font" in
            Linux*)
                linkfont opentype/public/libertine
                ;;
            TeX*)
                linkfont opentype/public/tex-gyre
                ;;
            CMU*)
                linkfont opentype/public/cm-unicode
                ;;
            *Torunska*)
                linkfont opentype/public/antt
                ;;
            *Poltawskiego*)
                linkfont opentype/gust/poltawski
                ;;
            PT*)
                linkfont truetype/paratype
                ;;
            Iwona*)
                linkfont opentype/nowacki/iwona
                ;;
            Noto*)
                linkfont truetype/google/noto
                ;;
            DejaVu*)
                linkfont $texfontsdir/truetype/public/dejavu
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

        # Check that font is installed successfully
        if ! fc-list "$font" | grep -q style; then
            echo "Failed to install $font"
            exit 3;
        fi
    fi
done
