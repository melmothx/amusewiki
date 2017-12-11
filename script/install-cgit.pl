#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use Cwd;
use Data::Dumper;
use Getopt::Long;
use AmuseWikiFarm::Utils::CgitSetup;

binmode STDOUT, ":encoding(utf-8)";

my $cgitversion = 'v1.1';
my ($reinstall, $help);

GetOptions(
           'cgit-version=s' => \$cgitversion,
           'reinstall' => \$reinstall,
           'help' => \$help,
          ) or die;

if ($help) {
    print <<'HELP';

Usage ./script/install-cgit.pl [ options ]

By default, download and compile cgit, and install the configuration
file if missing.

Options:

 --help

 Show this help and exit

 --reinstall

 Normally, cgit is compiled only if the binary is missing. To force
 the recompiling, use this option.

 --cgit-version

 By default, v1.1 is installed. v0.10.2 is known to work as well.

HELP
    exit 2;
}

my $amw_home = getcwd();
my $applibs = catfile($amw_home, qw/lib AmuseWikiFarm/);
die "$applibs is not a directory, are we in the application root?"
  unless -d $applibs;

my $cgitsetup = AmuseWikiFarm::Utils::CgitSetup->new(amw_home => $amw_home);

my %paths = map { $_ => $cgitsetup->$_ } (qw/src www cgitsrc cgi
                                             gitsrc cache etc cgitrc lib/);

$cgitsetup->create_skeleton;

print Dumper(\%paths);

# check for system-wide cgit in known locations (debian and freebsd)

if (!$cgitsetup->cgi_exists) {
    my $system_wide_location;
    my @locations = ('/usr/lib/cgit/cgit.cgi',
                     '/var/www/cgi-bin/cgit', # centos
                     '/usr/local/www/cgit/cgit.cgi');

    foreach my $loc (@locations) {
        if (-f $loc and -x $loc ) {
            $system_wide_location = $loc;
            last;
        }
    }
    if ($system_wide_location) {
        mkdir $cgitsetup->www unless -d $cgitsetup->www;
        open (my $fh, '>', $cgitsetup->cgi) or die "Cannot open " . $cgitsetup->cgi;
        my $rcfile = $cgitsetup->cgitrc;
        print $fh <<"CGI";
#!/bin/sh

CGIT_CONFIG=$rcfile $system_wide_location "\$\@"
CGI
        close $fh;
        chmod 0755, $cgitsetup->cgi;
        chmod 0777, $cgitsetup->cache;
    print <<"EOF";
Directory for cgit cache is $paths{cache}.

Permissions right now are wide open. Please consider to chown it to
www-data (or whatever user is running fcgiwrap, and restore it to a
sensible 755.

EOF

        print "Wrapper installed in " . $cgitsetup->cgi . ", exiting now\n";
        exit;
    }
}


if (!$cgitsetup->cgi_exists || $reinstall) {
    compile();
}

sub compile {
    my $gnumake = `which gmake` eq '' ? 'make' : 'gmake'; # cgit Makefile require GNU Make extensions
    chdir $paths{src} or die $!;
    print getcwd() . "\n";
    unless (-d $paths{cgitsrc}) {
        print getcwd() . "\n";
        sysexec(qw/git clone/, 'git://git.zx2c4.com/cgit/');
        chdir $paths{cgitsrc} or die $!;
        print getcwd() . "\n";
        sysexec(qw/git submodule init/);
    }
    chdir $paths{cgitsrc} or die $!;
    print getcwd() . "\n";
    sysexec(qw/git fetch origin/);
    sysexec(qw/git checkout/, $cgitversion);
    sysexec(qw/git submodule update/);
    chdir $paths{gitsrc} or die $!;
    sysexec($gnumake, 'clean');
    chdir $paths{cgitsrc} or die $!;
    sysexec($gnumake, 'clean');
    sysexec($gnumake,
            "CGIT_SCRIPT_PATH=$paths{www}",
            "CGIT_CONFIG=$paths{cgitrc}",
            "CACHE_ROOT=$paths{cache}",
            "NO_LUA=1",
            "prefix=$paths{lib}",
            'install');

    chdir $amw_home or die $!;
    if (-f $paths{cgi}) {
        sysexec('strip', '--strip-unneeded', $paths{cgi});
    } else {
        die "$paths{cgi} was not installed!\n";
    }
    chmod 0777, $paths{cache};
    print <<"EOF";
Directory for cgit cache is $paths{cache}.

Permissions right now are wide open. Please consider to chown it to
www-data (or whatever user is running fcgiwrap, and restore it to a
sensible 755.

EOF
}

sub sysexec {
    my (@args) = @_;
    my $cmdline = join(' ', @args);
    print "Executing $cmdline\n";
    system(@args) == 0 or die "$cmdline failed $?";
}

