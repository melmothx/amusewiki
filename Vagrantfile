# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Using the officially recommended (https://www.vagrantup.com/docs/boxes.html#official-boxes) Bento box.
  config.vm.box = "bento/debian-9.6"

  # Map HTTP port to port 8080 on host machine to make web server available as http://localhost:8080/
  # Only allow access via 127.0.0.1 to disable public access.
  config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  packages = []

  # Install script/install.sh dependencies
  packages += %w[
    carton
    cpanminus
    fontconfig
    gcc
    ghostscript
    git
    graphicsmagick
    imagemagick
    make
    rsync
    shared-mime-info
    unzip
    xapian-tools
  ]

  packages << "nginx"

  packages += %w[cgit fcgiwrap]

  # Install TeX Live
  packages += %w[
    texlive-base
    texlive-fonts-recommended
    texlive-generic-recommended
    texlive-lang-all
    texlive-latex-base
    texlive-latex-extra
    texlive-latex-recommended
    texlive-luatex
    texlive-xetex
  ]

  # Install fonts
  packages += %w[
    fonts-cmu
    fonts-dejavu
    fonts-hosny-amiri
    fonts-linuxlibertine
    fonts-lmodern
    fonts-sil-charis
    fonts-sil-gentium
    fonts-sil-gentium-basic
    fonts-sil-scheherazade
    fonts-texgyre
    lmodern
  ]

  # Perl module compilation dependencies
  packages += %w[
    g++
    libssl-dev
    libxapian-dev
    libxml2-dev
    libexpat1-dev
  ]

  # Install Imager module dependencies
  packages += %w[
    libjpeg-dev
    libpng-dev
  ]

  # Install gettext required by /vagrant/script/upgrade_i18n
  packages << "gettext"

  # Install dependencies via APT
  config.vm.provision "apt", type: "shell", privileged: false, inline: <<-SHELL
    set -e

    # Workaround for https://www.debian.org/security/2019/dsa-4371 until Debian 9.7 is available as a bento box
    APT_ARGS='-o Acquire::http::AllowRedirect=false'
    sudo sed -i 's/httpredir\.debian\.org/cdn-fastly.deb.debian.org/' /etc/apt/sources.list
    sudo sed -i 's/security\.debian\.org/cdn-fastly.deb.debian.org/' /etc/apt/sources.list

    sudo apt-get $APT_ARGS update
    sudo apt-get $APT_ARGS install --no-install-recommends --no-install-suggests -y #{packages.join(' ')}
  SHELL

  # Configure Amusewiki
  config.vm.provision "amusewiki-configure", type: "shell", privileged: false, inline: <<-SHELL
    set -e

    cd /vagrant

    cp dbic.yaml.sqlite.example dbic.yaml

    script/install.sh
    carton exec script/configure.sh localhost
    carton exec script/amusewiki-generate-nginx-conf | sudo /bin/sh

    carton exec script/generate-systemd-unit-files
    sudo cp -v /tmp/tmp.*/amusewiki-*.service /etc/systemd/system/
    sudo chown root:root /etc/systemd/system/amusewiki-*
    sudo chmod 664 /etc/systemd/system/amusewiki-*

    # It is impossible to create socket on VirtualBox filesystem.
    # Move it to home as a workaround.
    sudo sed -i 's|unix:/vagrant/var/amw.sock|unix:/home/vagrant/amw.sock|' /etc/nginx/amusewiki_include
    sudo sed -i 's|/vagrant/var/amw.sock|/home/vagrant/amw.sock|' /etc/systemd/system/amusewiki-web.service

    # Don't enable amusewiki-cgit here, because it is already started on port 9015 in /etc/nginx/sites-enabled/amusewiki
    sudo systemctl enable --now amusewiki-jobber amusewiki-web
    sudo systemctl restart nginx
  SHELL

  config.vm.hostname = 'amusewiki'

  config.vm.post_up_message = <<~MESSAGE
    Amusewiki is running at http://localhost:8080/

    To change default password:
      $ vagrant ssh
      vagrant@amusewiki:~$ cd /vagrant/
      vagrant@amusewiki:~$ carton exec script/amusewiki-reset-password amusewiki

    Run tests with:
      vagrant@amusewiki:~$ carton exec prove -l
  MESSAGE
end
