#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Spec::Functions qw/catfile catdir/;
use Cwd;
chdir $FindBin::Bin or die;

my $basedir = getcwd();
my $wwwdir = catdir($basedir, "public_html");
my $gitdir = catdir($basedir, "git");
mkdir $wwwdir unless -d $wwwdir;
mkdir $gitdir unless -d $gitdir;


my ($spec, @wget_args) = @ARGV;

die <<"HELP" unless $spec;
Usage: $0 host:site_id [ optional wget arguments ]

E.g. $0 amusewiki.org:amw --username User --password Password

The host is the hostname without any protocol (HTTPS is always used).

The site_id is the code used to fetch the git archive (optional).

HELP


mirror_site(split(/:/, $spec));


sub mirror_site {
    my ($sitename, $git) = @_;
    chdir $basedir or die;
    my $site = "https://$sitename";
    chdir $wwwdir or die;
    mkdir $sitename unless -d $sitename;
    my $listing = catfile($sitename, 'mirror.ts.txt');
    my $log = catfile($sitename, 'mirror.log');
    unlink $log if -f $log;
    system(wget => '-x', '-o', $log, "$site/mirror.ts.txt", @wget_args)
      and warn "Failed to download $site/mirror.ts.txt, see $log for the details\n";
    unless (-f $listing) {
        warn "Couldn't retrieve $listing, skipping $sitename\n";
        return;
    }
    my $urls = catfile($sitename, 'mirror.download');
    open (my $out, '>', $urls) or die "$!";
    open (my $fh, '<', $listing) or die "$!";
    while (my $line = <$fh>) {
        chomp $line;
        my ($file, $ts) = split(/\#/, $line);
        if ($file && $ts) {
            my $target = catfile($sitename, mirror => $file);
            if (-f $target) {
                if ((stat($target))[9] != $ts) {
                    my $fetch = "$site/mirror/$file\n";
                    print $out $fetch;
                    unlink $target;
                }
            }
            else {
                print $out "$site/mirror/$file\n";
            }
        }
    }
    close $fh;
    close $out;
    if (-f $urls and -s $urls) {
        open (my $lst, '<', $urls) or die;
        print <$lst>;
        close $lst;
        system(wget => '-a', $log, '-x', '-N', '-i', $urls, @wget_args)
          and warn "Errors downloading $urls, check $log";
    }
    chdir $gitdir or die;
    if ($git) {
        if (-d "$git") {
            chdir $git;
            system(git => pull => '--quiet') and warn "Couldn't pull $git";
            chdir $basedir or die;
        }
        else {
            system(git => clone => "git://$sitename/git/$git.git") and warn "Couldn't clone $git";
        }
    }
                 
    
}
