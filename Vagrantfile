# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Using the officially recommended (https://www.vagrantup.com/docs/boxes.html#official-boxes) Bento box.
  config.vm.box = "bento/debian-9.5"

  # Map HTTP port to port 8080 on host machine to make web server available as http://localhost:8080/
  # Only allow access via 127.0.0.1 to disable public access.
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Install dependencies
  config.vm.provision "apt", type: "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx

    # Install dependencies
    apt-get install -y cpanminus make fontconfig imagemagick unzip graphicsmagick \
      shared-mime-info xapian-tools gcc

    # Install most requirements (from Makefile.PL and others) from the repository
    apt-get install -y                               \
      libarchive-zip-perl                            \
      libcatalyst-action-renderview-perl             \
      libcatalyst-devel-perl                         \
      libcatalyst-perl                               \
      libcatalyst-plugin-authentication-perl         \
      libcatalyst-plugin-authorization-roles-perl    \
      libcatalyst-plugin-configloader-perl           \
      libcatalyst-plugin-session-perl                \
      libcatalyst-plugin-session-state-cookie-perl   \
      libcatalyst-plugin-session-store-fastmmap-perl \
      libcatalyst-view-json-perl                     \
      libcatalyst-view-tt-perl                       \
      libcgi-compile-perl                            \
      libcgi-emulate-psgi-perl                       \
      libcrypt-openssl-x509-perl                     \
      libdaemon-control-perl                         \
      libdata-dumper-concise-perl                    \
      libdbd-sqlite3-perl                            \
      libdbix-class-perl                             \
      libemail-valid-perl                            \
      libfcgi-perl                                   \
      libfcgi-procmanager-perl                       \
      libgit-wrapper-perl                            \
      libhttp-browserdetect-perl                     \
      libhttp-lite-perl                              \
      libhttp-parser-perl                            \
      libhttp-tiny-perl                              \
      libimager-perl                                 \
      libjavascript-packer-perl                      \
      liblocale-po-perl                              \
      liblog-dispatch-perl                           \
      libmime-types-perl                             \
      libmoose-perl                                  \
      libmoosex-nonmoose-perl                        \
      libnamespace-autoclean-perl                    \
      libpdf-api2-perl                               \
      libprotocol-acme-perl                          \
      libsearch-xapian-perl                          \
      libsql-translator-perl                         \
      libtemplate-tiny-perl                          \
      libterm-size-any-perl                          \
      libtest-www-mechanize-catalyst-perl            \
      libtest-www-mechanize-perl                     \
      libtext-diff-perl                              \
      libtext-unidecode-perl                         \
      libunicode-collate-perl                        \
      libuuid-tiny-perl                              \
      libxml-atom-perl                               \
      libxml-feedpp-perl                             \
      libxml-writer-perl                             \
      libyaml-tiny-perl                              \

    # Install local::lib
    apt-get install -y liblocal-lib-perl

    apt-get install -y git
  SHELL

  # Configure Amusewiki
  config.vm.provision "amusewiki-configure", type: "shell", privileged: false, inline: <<-SHELL
    git clone /vagrant amusewiki
    cd amusewiki

    eval `perl -Mlocal::lib`
    cp dbic.yaml.sqlite.example dbic.yaml

    script/install.sh
    script/configure.sh localhost
    script/amusewiki-generate-nginx-conf | sudo /bin/sh
  SHELL

  # Start Amusewiki services on every "vagrant up" or "vagrant reload"
  config.vm.provision "amusewiki-run", type: "shell", privileged: false, run: "always", inline: <<-SHELL
    cd amusewiki
    eval `perl -Mlocal::lib`

    ./init-all.sh start
  SHELL
end
