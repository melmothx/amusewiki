#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Data::Dumper;
use AmuseWikiFarm::Schema;
use File::Spec;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $mail = $ENV{AMW_LE_MAIL};
die "Missing AMW_LE_MAIL environment variable" unless $mail;

my $script =<<'EOF';
#!/bin/bash
set -e
set -x
export PATH=$HOME/simp_le/venv/bin:$PATH
reload=0
if [ $UID = 0 ]; then
    exit 2
fi
EOF


foreach my $site ($schema->resultset('Site')->all) {
    my @vhosts = ($site->canonical);
    push @vhosts, map { $_->name } $site->vhosts->all;
    my @command = (qw/simp_le -f key.pem -f fullchain.pem -f account_key.json/);
    push @command, '--email', $mail;
    push @command, '--default_root', File::Spec->rel2abs('root');
    push @command, map { -d => $_ } @vhosts;
    my $command = join (' ', @command);
    $script .= <<EOF;
# $vhosts[0]
mkdir -p \$HOME/ssl-certs/$vhosts[0];
cd \$HOME/ssl-certs/$vhosts[0];
if $command; then
    ((reload=reload+1))
fi

EOF
}

$script .= <<'EOF';
cd $HOME/ssl-certs
chmod 600 */key.pem
if [ $reload -gt 0 ];then
    exit 0
else
    exit 1
fi
EOF
print $script;
