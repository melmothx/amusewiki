#!/bin/sh
set -e

# needed packages
# microtype koma-script graphics tools enumitem ulem bigfoot wrapfig
# hyperref pdftexcmds infwarerr hycolor auxhook kvoptions zapfding
# atveryendbookmark fontspec polyglossia

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
