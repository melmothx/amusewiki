# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Using the officially recommended (https://www.vagrantup.com/docs/boxes.html#official-boxes) Bento box.
  config.vm.box = "bento/debian-9.5"

  # Map HTTP port to port 8080 on host machine to make web server available as http://localhost:8080/
  # Only allow access via 127.0.0.1 to disable public access.
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Install dependencies
  config.vm.provision "apt", type: "shell", privileged: false, inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y nginx

    # Install dependencies
    sudo apt-get install -y cpanminus make fontconfig imagemagick unzip graphicsmagick \
      shared-mime-info xapian-tools gcc

    # Install most requirements (from Makefile.PL and others) from the repository
    sudo apt-get install -y                          \
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

    sudo apt-get install --no-install-recommends --no-install-suggests -y \
      texlive-base                                                        \
      texlive-fonts-extra                                                 \
      texlive-fonts-recommended                                           \
      texlive-generic-recommended                                         \
      texlive-lang-all                                                    \
      texlive-latex-base                                                  \
      texlive-latex-extra                                                 \
      texlive-latex-recommended                                           \
      texlive-luatex                                                      \
      texlive-xetex                                                       \

    sudo apt-get install --no-install-recommends --no-install-suggests -y \
      fonts-cmu \
      fonts-texgyre

    # Required by /vagrant/script/upgrade_i18n
    sudo apt-get install --no-install-recommends --no-install-suggests -y gettext

    # Required by cgit
    sudo apt-get install --no-install-recommends --no-install-suggests -y libssl-dev

    # Install local::lib
    sudo apt-get install -y liblocal-lib-perl
    echo 'eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"' >>~/.bashrc
  SHELL

  # Configure Amusewiki
  config.vm.provision "amusewiki-configure", type: "shell", privileged: false, inline: <<-SHELL
    cd /vagrant

    eval `perl -Mlocal::lib`
    cp dbic.yaml.sqlite.example dbic.yaml

    script/install.sh
    script/configure.sh localhost
    script/amusewiki-generate-nginx-conf | sudo /bin/sh
    sudo sed -i s/www-data/vagrant/ /etc/nginx/nginx.conf

    # It is impossible to create socket on VirtualBox filesystem.
    # Move it to home as a workaround.
    sudo sed -i 's|unix:/vagrant/var/amw.sock|unix:/home/vagrant/amw.sock|' /etc/nginx/amusewiki_include
  SHELL

  # Start Amusewiki services on every "vagrant up" or "vagrant reload"
  config.vm.provision "amusewiki-run", type: "shell", privileged: false, run: "always", inline: <<-SHELL
    cd /vagrant
    eval `perl -Mlocal::lib`
    script/jobber.pl start
    script/amusewikifarm_fastcgi.pl start -l /home/vagrant/amw.sock -d
    sudo service nginx restart
  SHELL
end
