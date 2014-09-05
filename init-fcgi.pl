#!/usr/bin/env perl

use warnings;
use strict;
use Daemon::Control;
use File::Basename;
use File::Spec;

my $script = $0;

my $fullpath = File::Spec->rel2abs($script);

my ($name, $basedir, $suffix) = fileparse($fullpath);

my $program = File::Spec->catfile($basedir, qw/script amusewikifarm_fastcgi.pl/);

my $vardir = File::Spec->catdir($basedir, 'var');
unless (-d $vardir) {
    mkdir $vardir or die $!;
};

die "Couldn't find $program" unless (-f $program);
my $uid = (stat($program))[4];
my $gid = (stat($program))[5];
my $socket = File::Spec->catfile($vardir, 'amw.sock');

die "Don't run as root!" unless $uid && $gid;

my $workers = $ENV{AMW_WORKERS} || 1;

Daemon::Control->new({
                      name => "amusewiki-webapp",
                      lsb_start   => '$syslog $remote_fs',
                      lsb_stop    => '$syslog',
                      lsb_sdesc   => 'AmuseWiki',
                      lsb_desc    => 'AmuseWiki Catalyst app',
                      program =>  $program,
                      uid => $uid,
                      gid => $gid,
                      program_args => [ -l => $socket,
                                        -n => $workers,
                                        '--keeperr' ],
                      pid_file    => File::Spec->catfile($vardir, 'amw.pid'),
                      stderr_file => File::Spec->catfile($vardir, 'amw.err'),
                      stdout_file => File::Spec->catfile($vardir, 'amw.log'),
                      directory => $basedir,
                      fork => 2,
                     })->run;


