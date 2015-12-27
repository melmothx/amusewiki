#!/bin/sh

# Automated installer for amusewiki

set -e

AMWHOME=`pwd`
TEXMIRROR=ctan.ijs.si/tex-archive
AMWLOGFILE=`tempfile`

missing='no'
for command in perl cpanm fc-cache convert gm update-mime-database delve openssl \
               hostname make gcc wget git unzip rsync; do
    echo -n "Checking if $command is present: "
    if which $command > /dev/null; then
        echo "YES";
    else
        if [ $command = 'delve' ]; then
            echo "NO, please install xapian and the devel package"
        elif [ $command = 'make' ]; then
            echo "NO, please install build essential utils"
        elif [ $command = 'gm' ]; then
            echo "NO, please install graphicsmagick"
        else
            echo "NO, please install it"
        fi
        missing='yes'
    fi
done

if [ "`hostname -d`x" = "x" ]; then
    echo "I can't determine your domain name with hostname -d, bailing out"
    exit 2;
else
    echo "Your domain is `hostname -d`"
fi
hostname=amusewiki.`hostname -d`;

# even centos is suggested to listen here
# https://www.howtoforge.com/serving-cgi-scripts-with-nginx-on-centos-6.0-p2
echo -n "Checking if fcgiwrap is listening: "
if [ -S /var/run/fcgiwrap.socket ]; then
    echo "OK";
else
    echo "fcgiwrap socket in /var/run/fcgiwrap.socket not found! Needed for cgit";
    exit 2;
fi


if [ "$missing" != "no" ]; then
    cat <<EOF
Missing core utilities, cannot proceed. Please install them:

 - a working perl with cpanm (i.e., you can install modules)
 - fontconfig (install it before installing texlive)
 - graphicsmagick (for thumbnails) and imagemagick (for preview generation)
 - a mime-info database: shared-mime-info on debian
EOF
    exit 2
fi

echo -n "Checking header files for ssl: ";

check_headers () {
    output=`tempfile`
    cat <<'EOF'  | gcc -o $output -xc -
#include <stdio.h>
#include <openssl/sha.h>
#include <openssl/ssl.h>
main() { printf("Hello World"); }
EOF
}

if check_headers; then
    echo "OK";
else
    echo "NO, please install libssl-dev (or openssl-devel)";
    exit 2
fi

show_dbic_setup () {
    cat <<EOF

Please create a database for the application. E.g., for mysql:

  mysql> create database amuse DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
  mysql> grant all privileges on amuse.* to amuse@localhost identified by XXX

Or, for postgres:

Login as root.

 su - postgres
 psql
 create user amuse with password 'XXXX';
 create database amuse owner amuse;

Copy dbic.yaml.<dbtype>.example to dbic.yaml and adjust the
credentials, and chmod it to 600.

Please note that if you use mysql you need to install (via package
manager or cpanm) DBD::mysql, while if you use postgresql you need
DBD::Pg. These dependencies are not installed automatically by us and
requires devel packages (libmysqlclient-dev, libpq-dev) to be
installed.

If you want to use sqlite3, just copy dbic.yaml.sqlite.example to
dbic.yaml. No further setup is required, but it's meant to be only for
development.

EOF
    exit 2
}

if [ -f 'dbic.yaml' ]; then
    chmod 600 dbic.yaml
else
    show_dbic_setup
fi


echo -n "Checking if I can install modules in my home..."

cpanm -q Text::Amuse

if which muse-quick.pl > /dev/null; then
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
# assert we can modify it and patch this stuff
cpanm -q --reinstall CAM::PDF
script/patch-cam-pdf.sh
make

# check if I can access to the db


echo -n "Checking DB connection: "
if perl -I lib -MAmuseWikiFarm::Schema -MData::Dumper\
        -e 'AmuseWikiFarm::Schema->connect("amuse")->storage->dbh or die'; then
    echo "OK"
else
    show_dbic_setup
fi

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
EOF
    ./install-tl -repository http://$TEXMIRROR/systems/texlive/tlnet \
                 -profile amw.profile
    cd $AMWHOME
}

echo -n "Checking local installation of TeX live: ";
if [ -d $HOME/texlive/2015/bin ]; then
    echo "OK";
else
    install_texlive
fi
    
texbindir=`find $HOME/texlive/2015/bin -maxdepth 1 -mindepth 1 -type d | head -1`
if [ ! -f "$texbindir/xetex" ]; then
    echo "Something is wrong $texbindir/xetex doesn't exist!";
    exit 2;
fi
export PATH=$texbindir:$PATH

cat <<EOF >> $AMWLOGFILE
Please add to your .bashrc (or equivalent):

export PATH=$texbindir:\$PATH

EOF

if [ `which xelatex` !=  "$texbindir/xelatex" ]; then
    echo "Cannnot find xelatex in $texbindir, something went wrong!";
fi

# install the first site and the first user. No PDF compile
echo "Bootstrapping the initial site with the documentation"


./script/install_amw_site.pl --hostname "$hostname" --email "`whoami`@$hostname">> $AMWLOGFILE

echo "Installing needed JS"
./script/install_js.sh
./script/install_fonts.sh

cd $AMWHOME/font-preview
./gen.sh

cd $AMWHOME/webfonts
./populate-webfonts.pl

cd $AMWHOME
./script/install-cgit.pl
# avoid use of root for this, so fcgi wrap can write here
chmod 777 $AMWHOME/opt/cache/cgit

cat <<EOF
Directory for cgit cache is $AMWHOME/opt/cache/cgit

Permissions right now are wide open. Please consider to chown it to
www-data (or whatever user is running fcgiwrap, and restore it to a
sensible 755.

EOF

./script/generate-nginx-conf.pl >> $AMWLOGFILE

cat <<EOF

Setting up logger. Please note that by default, application errors are
sent to info@amusewiki.org (so bugs can be fixed promptly). This is
may or may not be what you want, and may have somehow sensitive info
inside (like session ids).

You are welcome to edit log4perl.local.conf (read the comments) to
suit your needs.

EOF

cp log4perl.conf log4perl.local.conf
sed -i "s/localhost/$hostname/" log4perl.local.conf
sed -i "s/amuse@/`whoami`@/" log4perl.local.conf

if git clone https://github.com/kuba/simp_le opt/simp_le; then
    echo "Let's encrypt client has been downloaded into `pwd`/opt/simp_le"
    echo "See the amusewiki INSTALL.txt and https://github.com/kuba/simp_le to finish the installation"
fi

cat $AMWLOGFILE
rm $AMWLOGFILE

echo "Starting up application"
./init-all.sh start
