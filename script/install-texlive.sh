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

year=2023

if [ -d $homedir/local/texlive ]; then
    echo "Moving old installation to backup directory"
    mv $homedir/local/texlive $homedir/local/texlive-$(date -I)
fi
mkdir -p $homedir/local/texlive
mkdir -p $homedir/local/install-texlive
cd $homedir/local/install-texlive

TEXMIRROR=ctan.ijs.si/tex-archive
echo "Installing TeX live $year"
# remove all stray files
rm -rfv install-tl-*
wget -O install-tl-unx.tar.gz \
     https://$TEXMIRROR/systems/texlive/tlnet/install-tl-unx.tar.gz
tar -xzvf install-tl-unx.tar.gz
# use shell expansion
cd install-tl-20*
arch=`./install-tl --print-arch`

cat <<EOF >> amusewiki.profile
selected_scheme scheme-custom
TEXDIR $homedir/local/texlive/$year
TEXMFCONFIG ~/.amusewiki-texlive-$year/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL $homedir/local/texlive/texmf-local
TEXMFSYSCONFIG $homedir/local/texlive/$year/texmf-config
TEXMFSYSVAR $homedir/local/texlive/$year/texmf-var
TEXMFVAR ~/.amusewiki-texlive-$year/texmf-var
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

./install-tl -repository https://$TEXMIRROR/systems/texlive/tlnet \
             -profile amusewiki.profile

export PATH="$homedir/local/texlive/$year/bin/$arch:$PATH"
$homedir/local/texlive/$year/bin/$arch/tlmgr install \
        microtype koma-script graphics tools enumitem ulem bigfoot wrapfig     \
        hyperref pdftexcmds infwarerr hycolor auxhook kvoptions zapfding       \
        atveryend bookmark fontspec polyglossia xindy xetex luatex imakeidx    \
        latex-bin epstopdf epstopdf-pkg ncctools luatexbase texdoc beamer      \
        pstricks fp pst-text xcolor geometry bidi zref auxhook chngcntr        \
        marginnote pst-barcode \
        xetex-pstricks \
        footmisc \
        carlisle lua-uni-algos \
        xecjk luatexja ctex \
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
        hyphen-turkmen hyphen-ukrainian hyphen-uppersorbian hyphen-welsh       \
        babel-albanian babel-azerbaijani babel-basque babel-belarusian         \
        babel-bosnian babel-breton babel-bulgarian babel-catalan               \
        babel-croatian babel-czech babel-danish babel-dutch babel-english      \
        babel-esperanto babel-estonian babel-finnish babel-french              \
        babel-friulan babel-galician babel-georgian babel-german babel-greek   \
        babel-hebrew babel-hungarian babel-icelandic babel-indonesian          \
        babel-interlingua babel-irish babel-italian babel-japanese             \
        babel-kurmanji babel-latin babel-latvian babel-macedonian babel-malay  \
        babel-norsk babel-occitan babel-piedmontese babel-polish               \
        babel-portuges babel-romanian babel-romansh babel-russian babel-samin  \
        babel-scottish babel-serbian babel-serbianc babel-slovak               \
        babel-slovenian babel-sorbian babel-spanish babel-swedish babel-thai   \
        babel-turkish babel-ukrainian babel-vietnamese babel-welsh

echo "TeXlive installed in $homedir/local/texlive, bin path is $homedir/local/texlive/$year/bin/$arch"

