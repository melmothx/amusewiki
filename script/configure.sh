#!/bin/sh

set -e

hostname=$1

if [ "x$hostname" = "x" ]; then
    if [ "`hostname -d`x" = "x" ]; then
        echo "I can't determine your domain name with hostname -d, bailing out"
        echo "Please pass the desired hostname as argument"
        exit 2;
    else
        hostname=amusewiki.`hostname -d`;
        echo "Your domain is `hostname -d`, setting up initial site as $hostname"
    fi
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

ABORTING INSTALLATION (you need to setup the database).

EOF
    exit 2
}

if [ -f 'dbic.yaml' ]; then
    chmod 600 dbic.yaml
else
    show_dbic_setup
fi

# check if I can access to the db

echo -n "Checking DB connection: "
if perl -I lib -MAmuseWikiFarm::Schema -MData::Dumper\
        -e 'AmuseWikiFarm::Schema->connect("amuse")->storage->dbh or die'; then
    echo "OK"
else
    show_dbic_setup
fi

./script/amusewiki-create-doc-site --hostname "$hostname" --email "`whoami`@$hostname"

# install the first site and the first user. No PDF compile
echo "Bootstrapping the initial site with the documentation"

echo "#####################################################"
echo
./script/amusewiki-generate-nginx-conf
echo "#####################################################"
echo

echo "You may want to start up application with ./init-all.sh start"
