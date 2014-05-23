#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;
use File::Basename;
use File::Spec;

my $script = $0;

my $fullpath = File::Spec->rel2abs($script);

my ($name, $basedir, $suffix) = fileparse($fullpath);

my $program = File::Spec->catfile($basedir, qw/script jobber.pl/);

my $vardir = File::Spec->catdir($basedir, 'var');
unless (-d $vardir) {
    mkdir $vardir or die $!;
};

die "Couldn't find $program" unless (-f $program);
my $uid = (stat($program))[4];
my $gid = (stat($program))[5];

die "Don't run as root!" unless $uid && $gid;

Daemon::Control->new({
                      name => "amusewiki-jobber",
                      lsb_start   => '$syslog $remote_fs',
                      lsb_stop    => '$syslog',
                      lsb_sdesc   => 'AmuseWiki Jobber',
                      lsb_desc    => 'AmuseWiki Jobber',
                      program =>  $program,
                      uid => $uid,
                      gid => $gid,
                      pid_file    => File::Spec->catfile($vardir, 'jobs.pid'),
                      stderr_file => File::Spec->catfile($vardir, 'jobs.err'),
                      stdout_file => File::Spec->catfile($vardir, 'jobs.log'),
                      directory => $basedir,
                      fork => 2,
                     })->run;
