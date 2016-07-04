#!/bin/sh

# Automated installer for amusewiki

set -e

AMWHOME=`pwd`
TEXMIRROR=ctan.ijs.si/tex-archive

missing='no'
for command in perl cpanm fc-cache convert gm update-mime-database xapian-check openssl \
               make gcc wget git unzip rsync; do
    echo -n "Checking if $command is present: "
    if which $command > /dev/null; then
        echo "YES";
    else
        if [ $command = 'xapian-check' ]; then
            echo "NO, please install xapian and its utils"
        elif [ $command = 'make' ]; then
            echo "NO, please install build essential utils"
        elif [ $command = 'gm' ]; then
            echo "NO, please install graphicsmagick"
        else
            echo "NO, please install $command"
        fi
        missing='yes'
    fi
done

if [ "$missing" != "no" ]; then
    cat <<EOF
Missing core utilities, cannot proceed. Please install them:

 - a working perl with cpanm (i.e., you can install modules)
 - fontconfig (install it before installing texlive)
 - graphicsmagick (for thumbnails) and imagemagick (for preview generation)
 - a mime-info database: shared-mime-info on debian
 - openssl
 - general utils: wget, git, unzip, rsync
EOF
    exit 2
fi

echo -n "Checking if I can install modules in my home..."

cpanm -q Text::Amuse::Compile

if which muse-compile.pl > /dev/null; then
    echo "OK, I can install Perl5 modules"
else
    cat <<"EOF"

It looks like I can't install modules. Please be sure to have this
line in your $HOME/.bashrc (or the rc file of your shell)

eval `perl -I ~/perl5/lib/perl5/ -Mlocal::lib`

Then login/logout

EOF
    exit 2
fi

echo "Installing perl modules"
cpanm -q Log::Dispatch Log::Log4perl Module::Install Mail::Send \
      Log::Dispatch::File::Stamped \
      Module::Install::Catalyst
cpanm -q --installdeps .
make

install_texlive () {
    cd $HOME
    echo "Installing TeX live 2015 in your home under texlive"
    # remove all stray files
    rm -rfv install-tl-*
    wget -O install-tl-unx.tar.gz \
         http://$TEXMIRROR/systems/texlive/tlnet/install-tl-unx.tar.gz
    tar -xzvf install-tl-unx.tar.gz
    # use shell expansion
    cd install-tl-201*
    cat <<EOF >> amw.profile
selected_scheme scheme-full
TEXDIR $HOME/texlive/2015
TEXMFCONFIG ~/.texlive2015/texmf-config
TEXMFHOME ~/texmf
TEXMFLOCAL $HOME/texlive/texmf-local
TEXMFSYSCONFIG $HOME/texlive/2015/texmf-config
TEXMFSYSVAR $HOME/texlive/2015/texmf-var
TEXMFVAR ~/.texlive2015/texmf-var
option_desktop_integration 0
option_doc 0
option_menu_integration 0
option_src 0
EOF
    ./install-tl -repository http://$TEXMIRROR/systems/texlive/tlnet \
                 -profile amw.profile
    cd $AMWHOME
}

echo -n "Checking installation of TeX live: ";
if which xelatex > /dev/null; then
    echo "OK";
else
    echo "TeXlive is packaged for a lot of OSes and you're suggested"
    echo "to install it (in its full variant) from the repository."
    echo "Otherwise see https://www.tug.org/texlive/"
    exit 2;
fi

echo "Installing needed JS"
./script/install_js.sh
./script/install_fonts.sh

cd $AMWHOME/font-preview
./gen.sh

cd $AMWHOME
./script/amusewiki-populate-webfonts $AMWHOME/webfonts

cd $AMWHOME
./script/install-cgit.pl

cat <<EOF
Please add to your .bashrc (or equivalent):

export PATH=$texbindir:\$PATH

EOF
