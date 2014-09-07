#!/usr/bin/env perl

#   location /git/ {
#       root /srv/cgit/www;
#        fastcgi_split_path_info ^/git()(.*);
#        fastcgi_param PATH_INFO       $fastcgi_path_info;
#        fastcgi_param  SCRIPT_FILENAME $document_root/cgit.cgi;        
#        fastcgi_param  SCRIPT_NAME     $fastcgi_script_name;
#        fastcgi_param  REQUEST_METHOD      $request_method;
#        fastcgi_param  CONTENT_TYPE        $content_type;
#        fastcgi_param  CONTENT_LENGTH      $content_length;
#
#        fastcgi_param  REQUEST_URI     $request_uri;
#        fastcgi_param  DOCUMENT_URI        $document_uri;
#        fastcgi_param  DOCUMENT_ROOT       $document_root;
#        fastcgi_param  SERVER_PROTOCOL     $server_protocol;
#        
#        fastcgi_param  GATEWAY_INTERFACE   CGI/1.1;
#        fastcgi_param  SERVER_SOFTWARE     nginx/$nginx_version;
#        
#        fastcgi_param  REMOTE_ADDR     $remote_addr;
#        fastcgi_param  REMOTE_PORT     $remote_port;
#        fastcgi_param  SERVER_ADDR     $server_addr;
#        fastcgi_param  SERVER_PORT     $server_port;
#        fastcgi_param  SERVER_NAME     $server_name;
#        
#        fastcgi_param  HTTPS           $https;
#        fastcgi_param   QUERY_STRING    $args;
#        fastcgi_param   HTTP_HOST       $server_name;
#
#        fastcgi_pass    unix:/var/run/fcgiwrap.socket;
#
#    }


use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile/;
use Cwd;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my @vhosts = $schema->resultset('Vhost')->search(
                                                 {},
                                                 { order_by => [qw/site_id
                                                                   name/]}
                                                )->all;
my $hosts = join("\n" . (" " x 16), map { $_->name } @vhosts);

my $cgit_path = catfile(qw/root git cgi-bin cgit.cgi/);

my $cgit = "";

my $amw_home = getcwd;

if (-f $cgit_path) {
    $cgit = <<"EOF";

    location /git/ {
        fastcgi_split_path_info ^/git()(.*);
        fastcgi_param   PATH_INFO       \$fastcgi_path_info;
        fastcgi_param   SCRIPT_FILENAME \$document_root/git/cgi-bin/cgit.cgi;
        fastcgi_param   SCRIPT_NAME     \$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_pass    unix:/var/run/fcgiwrap.socket;
    }

EOF
}

print <<"EOF";
server {
    server_name $hosts;
    root $amw_home/root;
    location = /rss.xml {
        rewrite ^/rss\\.xml\$ /feed permanent;
    }

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
        access_log /var/log/nginx/library.log hitcount;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_NAME '';
        fastcgi_param PATH_INFO   \$fastcgi_script_name;
        fastcgi_param HTTP_X_SENDFILE_TYPE X-Accel-Redirect;
        fastcgi_param HTTP_X_ACCEL_MAPPING $amw_home=/private;
        fastcgi_pass  unix:$amw_home/var/amw.sock;
    }
}
EOF


