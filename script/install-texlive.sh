#!/bin/sh
set -e

TEXMIRROR=ctan.ijs.si/tex-archive
cd "$HOME"
echo "Installing TeX live 2018 in your home under texlive"
# remove all stray files
rm -rfv install-tl-*
wget -O install-tl-unx.tar.gz \
     http://$TEXMIRROR/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzvf install-tl-unx.tar.gz
# use shell expansion
cd install-tl-201*
cat <<EOF >> amw.profile
selected_scheme scheme-full
TEXDIR $HOME/texlive/2018
TEXMFCONFIG ~/.texlive2018/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL $HOME/texlive/texmf-local
TEXMFSYSCONFIG $HOME/texlive/2018/texmf-config
TEXMFSYSVAR $HOME/texlive/2018/texmf-var
TEXMFVAR ~/.texlive2018/texmf-var
option_doc 0
option_src 0
EOF
./install-tl -repository http://$TEXMIRROR/systems/texlive/tlnet \
             -profile amw.profile
