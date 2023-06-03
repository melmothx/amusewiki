#!/bin/sh

set -e
# set -x

# enforce the correct path
cd `dirname $0`
cd ..

cwd=$(pwd)
echo "Checking and installing missing fonts"

has_local_tlmgr=""

for i in $cwd/local/texlive/*/bin/*/tlmgr; do
    if [ -x $i ]; then
        echo "Found local tlmgr: $i"
        has_local_tlmgr=$i
    fi
done

linkfont () {
    package=$(basename "$1")
    if [ -n "$package" ]; then
        if [ -n "$has_local_tlmgr" ]; then
            $has_local_tlmgr install $package
        fi
    fi
    for texfontsdir in $cwd/local/texlive/*/texmf-dist/fonts \
                       "/usr/local/share/texmf-dist/fonts" \
                       "/usr/share/texmf/fonts" \
                       "/usr/share/texlive/texmf-dist/fonts"; do
        if [ -d "$texfontsdir/$1" ]; then
            ln -sf "$texfontsdir/$1"
            return 0
        fi
    done
    return 0
}

mkdir -p "$HOME/.fonts"
cd "$HOME/.fonts"
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
            DejaVu*)
                linkfont truetype/public/dejavu
                ;;
            *Charis*)
                rm -fv charis
                wget -O "$HOME/CharisSIL.zip" \
                     https://software.sil.org/downloads/r/charis/CharisSIL-6.200.zip
                unzip -d "$HOME/.fonts/charis" "$HOME/CharisSIL.zip"
                ;;
            *)
                echo "Unhandled font $font!"
                ;;
        esac
        fc-cache -f

        # Check that font is installed successfully
        if ! fc-list "$font" | grep -q style; then
            echo "Failed to install $font"
            # exit 3
        fi
    fi
done
