#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;
use File::Basename;
use File::Spec;
use Cwd;
use Getopt::Long;

my %opts;
GetOptions (\%opts, 'socket=s') or die;

my $basedir = getcwd();
my $vardir = File::Spec->catdir($basedir, 'var');
unless (-d $vardir) {
    mkdir $vardir or die $!;
};
my $uid = (stat($0))[4];
my $gid = (stat($0))[5];
my $socket = $opts{socket} || File::Spec->catfile($vardir, 'amw.sock');
my $psgi = File::Spec->catfile($basedir, psgi => 'amusewiki.psgi');

die "Don't run as root!" unless $uid && $gid;
die "Couldn't find $psgi" unless -f $psgi;

my $workers = $ENV{AMW_WORKERS} || 3;

Daemon::Control->new({
                      name => "amusewiki-webapp",
                      lsb_start   => '$syslog $remote_fs',
                      lsb_stop    => '$syslog',
                      lsb_sdesc   => 'AmuseWiki',
                      lsb_desc    => 'AmuseWiki Catalyst app',
                      program =>  'plackup',
                      uid => $uid,
                      gid => $gid,
                      program_args => [
                                       '-s' => 'FCGI',
                                       '--listen' => $socket,
                                       '--nproc' => $workers,
                                       '-E' => 'deployment',
                                       $psgi,
                                      ],
                      pid_file    => File::Spec->catfile($vardir, 'amw.pid'),
                      stderr_file => File::Spec->catfile($vardir, 'amw.err'),
                      stdout_file => File::Spec->catfile($vardir, 'amw.log'),
                      directory => $basedir,
                      fork => 2,
                     })->run;


