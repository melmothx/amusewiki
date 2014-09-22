#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile/;
use Cwd;
use Getopt::Long;
use File::Temp;

my $logformat = 'combined';
GetOptions ('logformat=s' => \$logformat) or die;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my @vhosts;
my @sites = $schema->resultset('Site')->search(undef, { order_by => [qw/id/] })->all;
foreach my $site (@sites) {
    push @vhosts, $site->all_site_hostnames;
}

my $hosts = join("\n" . (" " x 16),  @vhosts);

my $cgit_path = catfile(qw/root git cgit.cgi/);

# globals
my $cgit = "";
my $amw_home = getcwd;

if (-f $cgit_path) {
    $cgit = <<"EOF";

    location /git/ {
        access_log /var/log/nginx/amusewiki.log $logformat;
        fastcgi_split_path_info ^/git()(.*);
        fastcgi_param   PATH_INFO       \$fastcgi_path_info;
        fastcgi_param   SCRIPT_FILENAME \$document_root/git/cgit.cgi;
        fastcgi_param   SCRIPT_NAME     \$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_pass    unix:/var/run/fcgiwrap.socket;
    }

EOF
}

print_server_stanza($hosts);

my $dir = File::Temp->newdir(CLEANUP => 0)->dirname;


foreach my $site (@sites) {
    my $cn = $site->canonical;
    print_server_stanza($cn, 'ssl');
    my $cert_out = catfile($dir, $cn . '.crt');
    my $key_out =  catfile($dir, $cn . '.key');
    unless (-f "/etc/nginx/ssl/$cn.crt" and
            -f "/etc/nginx/ssl/$cn.key") {
        system(openssl => req => '-new',
               -newkey => 'rsa:4096',
               -days   => '3650',
               -nodes  => -x509 => -subj => "/CN=$cn",
               -keyout => $key_out,
               -out    => $cert_out) == 0 or die $!;
    }
}

warn "Self-signed certificates left (if needed) in $dir. Please
install them in /etc/nginx/ssl/ \n";



# then print out the ssl conf


sub print_server_stanza {
    my ($server_names, $ssl) = @_;
    print "server {\n";
    if ($ssl) {
        print <<"EOF"
    listen 443 ssl;
    ssl_certificate ssl/$server_names.crt;
    ssl_certificate_key ssl/$server_names.key;
EOF
    }
    print <<"EOF";
    server_name $server_names;
    root $amw_home/root;

    # LEGACY STUFF
    rewrite ^/lib/(.*)\$ /library/\$1 permanent;
    rewrite ^/HTML/(.*)\.html\$ /library/\$1 permanent;
    rewrite ^/pdfs/a4/(.*)_a4\.pdf /library/\$1.pdf permanent;
    rewrite ^/pdfs/letter/(.*)_letter\.pdf /library/\$1.pdf permanent;
    rewrite ^/pdfs/a4_imposed/(.*)_a4_imposed\.pdf /library/\$1.a4.pdf permanent;
    rewrite ^/pdfs/letter_imposed/(.*)_letter_imposed\.pdf /library/\$1.lt.pdf permanent;
    rewrite ^/print/(.*)\.html /library/\$1.html permanent;
    rewrite ^/epub/(.*)\.epub /library/\$1.epub permanent;
    # END LEGACY STUFF

    location /src/ {
        deny all;
    }
    location /themes/ {
        deny all;
    }
    location /private/repo/ {
        internal;
        alias $amw_home/repo/;
    }
    location /private/staging/ {
        internal;
        alias $amw_home/staging/;
    }
$cgit
    location / {
        try_files \$uri \@proxy;
        expires max;
    }
    location \@proxy {
        access_log /var/log/nginx/amusewiki.log $logformat;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_NAME '';
        fastcgi_param PATH_INFO   \$fastcgi_script_name;
        fastcgi_param HTTP_X_SENDFILE_TYPE X-Accel-Redirect;
        fastcgi_param HTTP_X_ACCEL_MAPPING $amw_home=/private;
        fastcgi_pass  unix:$amw_home/var/amw.sock;
    }
}

EOF
}

