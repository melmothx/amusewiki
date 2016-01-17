#!/usr/bin/env perl

use utf8;
use warnings;
use strict;
use Daemon::Control;
use File::Basename;
use File::Spec;
use Cwd;

my $basedir = getcwd();
my $program = File::Spec->catfile($basedir, "script", "amusewiki-jobber");
my $vardir = File::Spec->catdir($basedir, 'var');
unless (-d $vardir) {
    mkdir $vardir or die $!;
};

die "Couldn't find $program" unless -f $program;

Daemon::Control->new({
                      name => "amusewiki-jobber",
                      program =>  'perl',
                      program_args => [ -I => 'lib', $program ],
                      pid_file    => File::Spec->catfile($vardir, 'jobs.pid'),
                      stderr_file => File::Spec->catfile($vardir, 'jobs.err'),
                      stdout_file => File::Spec->catfile($vardir, 'jobs.log'),
                      directory => $basedir,
                      fork => 2,
                     })->run;


