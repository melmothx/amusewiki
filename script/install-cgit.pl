#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use Cwd;
use Data::Dumper;
use Getopt::Long;

binmode STDOUT, ":encoding(utf-8)";

my $cgitversion = 'v0.11.2';
my ($hostname, $reinstall, $reconfigure, $help);

GetOptions(
           'hostname=s' => \$hostname,
           'cgit-version=s' => \$cgitversion,
           'reconfigure' => \$reconfigure,
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

 --reconfigure

 Skip the download and compile step, and just reconfigure cgitrc with
 the values from the database (i.e., sites with cgi integration set)

 --hostname <git.mysite.org>

 If not provided, the hostname will be the canonical hostname for each
 site. Otherwise always use this one. This is used for the clone-url.
 Please note that if the git archive doesn't have a
 git-daemon-export-ok file, the clone-url is not generated.

 --cgit-version

 By default, v0.11.2 is installed. v0.10.2 is known to work as well.

HELP
    exit 2;
}

my $amw_home = getcwd();
my $applibs = catfile($amw_home, qw/lib AmuseWikiFarm/);
die "$applibs is not a directory, are we in the application root?"
  unless -d $applibs;

my %paths = (
             src => catdir($amw_home, qw/opt src/),
             www => catdir($amw_home, qw/root git/),
             cgitsrc => catdir($amw_home, qw/opt src cgit/),
             cgi => catfile($amw_home, qw/root git cgit.cgi/),
             gitsrc => catdir($amw_home, qw/opt src cgit git/),
             cache => catdir($amw_home, qw/opt cache cgit/),
             etc => catdir($amw_home, qw/opt etc/),
             cgitrc => catfile($amw_home, qw/opt etc cgitrc/),
             lib => catdir($amw_home, qw/opt usr/),
           );

foreach my $dir (qw/src cache etc lib/) {
    make_path($paths{$dir}, { verbose => 1 }) unless -d $paths{$dir};
}
print Dumper(\%paths);

unless ($reconfigure) {
    compile();
}

if (! -f $paths{cgitrc} || $reconfigure) {
    install_conf();
}



sub compile {
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
    sysexec(qw/make clean/);
    chdir $paths{cgitsrc} or die $!;
    sysexec(qw/make clean/);
    sysexec('make',
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
    print <<"CHOWN";
*******************************************************
**** Please chown $paths{cache} to www-data ****
*******************************************************
CHOWN

}

sub sysexec {
    my (@args) = @_;
    my $cmdline = join(' ', @args);
    print "Executing $cmdline\n";
    system(@args) == 0 or die "$cmdline failed $?";
}

sub install_conf {
    my $cgitrc = $paths{cgitrc};
    die "Missing cgitrc location" unless $cgitrc;
    print "Installing configuration file at $cgitrc\n";
    open (my $fh, '>:encoding(utf-8)', $cgitrc)
      or die "Cannot open $cgitrc\n";
    print $fh "####### automatically generated on " . localtime() . " ######\n\n";
    print $fh <<'CONFIG';
virtual-root=/git
enable-index-owner=0
robots="noindex, nofollow"
cache-size=1000
enable-commit-graph=1
embedded=1

CONFIG
    my $schema = AmuseWikiFarm::Schema->connect('amuse');
    die "Cannot connect to database, please read the doc!" unless $schema;

    foreach my $site ($schema->resultset('Site')->all) {
        next unless $site->cgit_integration;
        my $path = File::Spec->rel2abs(catdir($amw_home, 'repo',
                                              $site->id, ".git"));
        unless (-d $path) {
            warn "Repo $path not found!, skipping\n";
            next;
        }
        print $fh "repo.url=" . $site->id . "\n";
        print $fh "repo.path=" . $path . "\n";
        print $fh "repo.desc=" . $site->sitename . "\n";
        if (-f catfile($path, 'git-daemon-export-ok')) {
            my $githostname = $hostname || $site->canonical;
            print $fh "repo.clone-url=git://$githostname/git/" . $site->id .
              ".git\n";
            print $fh "\n\n";
        }
        print "Exported " . $site->id . " into cgit\n";
    }
    close $fh;
}
