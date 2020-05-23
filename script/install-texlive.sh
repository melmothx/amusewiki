#!/bin/sh
set -e

cd $(dirname $0)
cd ..
homedir=`pwd`

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


if [ -d $homedir/local/texlive ]; then
    echo "Moving old installation to backup directory"
    mv $homedir/local/texlive $homedir/local/texlive-$(date -I)
fi
mkdir -p $homedir/local/texlive
mkdir -p $homedir/local/install-texlive
cd $homedir/local/install-texlive

TEXMIRROR=ctan.ijs.si/tex-archive
echo "Installing TeX live 2020"
# remove all stray files
rm -rfv install-tl-*
wget -O install-tl-unx.tar.gz \
     http://$TEXMIRROR/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzvf install-tl-unx.tar.gz
# use shell expansion
cd install-tl-20*
arch=`./install-tl --print-arch`

cat <<EOF >> amusewiki.profile
selected_scheme scheme-custom
TEXDIR $homedir/local/texlive/2020
TEXMFCONFIG ~/.texlive2020/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL $homedir/local/texlive/texmf-local
TEXMFSYSCONFIG $homedir/local/texlive/2020/texmf-config
TEXMFSYSVAR $homedir/local/texlive/2020/texmf-var
TEXMFVAR ~/.texlive2020/texmf-var
binary_$arch 1
collection-basic 1
instopt_adjustpath 1
instopt_adjustrepo 1
instopt_letter 0
instopt_portable 1
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 1
tlpdbopt_file_assocs 1
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 1
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 1

EOF

./install-tl -repository http://$TEXMIRROR/systems/texlive/tlnet \
             -profile amusewiki.profile

export PATH="$homedir/local/texlive/2020/bin/$arch:$PATH"
$homedir/local/texlive/2020/bin/$arch/tlmgr install \
        microtype koma-script graphics tools enumitem ulem bigfoot wrapfig     \
        hyperref pdftexcmds infwarerr hycolor auxhook kvoptions zapfding       \
        atveryend bookmark fontspec polyglossia xindy xetex luatex imakeidx    \
        latex-bin epstopdf epstopdf-pkg ncctools luatexbase texdoc             \
        hyphen-afrikaans hyphen-ancientgreek hyphen-arabic hyphen-armenian     \
        hyphen-base hyphen-basque hyphen-belarusian hyphen-bulgarian           \
        hyphen-catalan hyphen-chinese hyphen-churchslavonic hyphen-coptic      \
        hyphen-croatian hyphen-czech hyphen-danish hyphen-dutch hyphen-english \
        hyphen-esperanto hyphen-estonian hyphen-ethiopic hyphen-farsi          \
        hyphen-finnish hyphen-french hyphen-friulan hyphen-galician            \
        hyphen-georgian hyphen-german hyphen-greek hyphen-hungarian            \
        hyphen-icelandic hyphen-indic hyphen-indonesian hyphen-interlingua     \
        hyphen-irish hyphen-italian hyphen-kurmanji hyphen-latin               \
        hyphen-latvian hyphen-lithuanian hyphen-macedonian hyphen-mongolian    \
        hyphen-norwegian hyphen-occitan hyphen-piedmontese hyphen-polish       \
        hyphen-portuguese hyphen-romanian hyphen-romansh hyphen-russian        \
        hyphen-sanskrit hyphen-serbian hyphen-slovak hyphen-slovenian          \
        hyphen-spanish hyphen-swedish hyphen-thai hyphen-turkish               \
        hyphen-turkmen hyphen-ukrainian hyphen-uppersorbian hyphen-welsh

echo "TeXlive installed in $homedir/local/texlive, bin path is $homedir/local/texlive/2020/bin/$arch"
