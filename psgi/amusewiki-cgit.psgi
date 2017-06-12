#!/usr/bin/env perl

use strict;
use warnings;

use Plack::App::WrapCGI;
use File::Spec;
my $cgitrc = File::Spec->rel2abs(File::Spec->catfile(qw/opt etc cgitrc/));
die "No cgitrc found" unless -f $cgitrc;

%ENV = (
        CGIT_CONFIG => $cgitrc,
       );

my @locations = ('/usr/lib/cgit/cgit.cgi',
                 '/var/www/cgi-bin/cgit', # centos
                 '/usr/local/www/cgit/cgit.cgi', # freebsd
                 File::Spec->rel2abs('root/git/cgit.cgi'), # installed by us
                );

my $cgit_exec;
foreach my $cgit (@locations) {
    if (-f $cgit) {
        $cgit_exec = $cgit;
        last;
    }
}

die "Couldn't find a cgit executable" unless $cgit_exec;

my $app = Plack::App::WrapCGI->new(script => $cgit_exec,
                                   execute => 1)->to_app;
