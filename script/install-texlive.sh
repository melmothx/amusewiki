#!/bin/sh
set -e

# needed packages
# microtype koma-script graphics tools enumitem ulem bigfoot wrapfig
# hyperref pdftexcmds infwarerr hycolor auxhook kvoptions zapfding
# atveryend bookmark fontspec polyglossia xindy xetex luatex imakeidx
# latex-bin epstopdf epstopdf-pkg
# hyphen-afrikaans hyphen-ancientgreek hyphen-arabic hyphen-armenian
# hyphen-base hyphen-basque hyphen-belarusian hyphen-bulgarian
# hyphen-catalan hyphen-chinese hyphen-churchslavonic hyphen-coptic
# hyphen-croatian hyphen-czech hyphen-danish hyphen-dutch hyphen-english
# hyphen-esperanto hyphen-estonian hyphen-ethiopic hyphen-farsi
# hyphen-finnish hyphen-french hyphen-friulan hyphen-galician
# hyphen-georgian hyphen-german hyphen-greek hyphen-hungarian
# hyphen-icelandic hyphen-indic hyphen-indonesian hyphen-interlingua
# hyphen-irish hyphen-italian hyphen-kurmanji hyphen-latin
# hyphen-latvian hyphen-lithuanian hyphen-macedonian hyphen-mongolian
# hyphen-norwegian hyphen-occitan hyphen-piedmontese hyphen-polish
# hyphen-portuguese hyphen-romanian hyphen-romansh hyphen-russian
# hyphen-sanskrit hyphen-serbian hyphen-slovak hyphen-slovenian
# hyphen-spanish hyphen-swedish hyphen-thai hyphen-turkish
# hyphen-turkmen hyphen-ukrainian hyphen-uppersorbian hyphen-welsh

TEXMIRROR=ctan.ijs.si/tex-archive
cd "$HOME"
echo "Installing TeX live 2019 in your home under texlive"
# remove all stray files
rm -rfv install-tl-*
wget -O install-tl-unx.tar.gz \
     http://$TEXMIRROR/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzvf install-tl-unx.tar.gz
# use shell expansion
cd install-tl-20*
cat <<EOF >> amw.profile
selected_scheme scheme-full
TEXDIR $HOME/texlive/2019
TEXMFCONFIG ~/.texlive2019/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL $HOME/texlive/texmf-local
TEXMFSYSCONFIG $HOME/texlive/2019/texmf-config
TEXMFSYSVAR $HOME/texlive/2019/texmf-var
TEXMFVAR ~/.texlive2019/texmf-var
option_doc 0
option_src 0
EOF
./install-tl -repository http://$TEXMIRROR/systems/texlive/tlnet \
             -profile amw.profile
