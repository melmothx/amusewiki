#!/bin/sh

# Automated installer for amusewiki

set -e

missing='no'
for command in perl cpanm fc-cache convert update-mime-database delve openssl \
               make gcc; do
    echo -n "Checking if $command is present: "
    if which $command > /dev/null; then
        echo "YES";
    else
        if [ $command == 'delve' ]; then
            echo "NO, please install xapian and the devel package"
        elif [ $command == 'make' ]; then
            echo "NO, please install build essential utils"
        else
            echo "NO, please install it"
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
cpanm -q Log::Dispatch Log::Log4perl Module::Install
cpanm -q Module::Install::Catalyst
cpanm -q --installdeps .

