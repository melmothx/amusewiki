#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use POSIX qw/nice setsid SIGTERM/;
use FindBin ();
use File::Basename ();
use File::Spec;
use Fcntl qw/:flock/;
use DateTime;
use Getopt::Long;
use lib 'lib';

use constant AMW_POLLING => $ENV{AMW_POLLING} || 5;

my ($foreground);

GetOptions(debug => \$foreground) or die;

$| = 1;


my $scriptname = File::Basename::basename($0);
my $script = File::Spec->catfile($FindBin::Bin, $scriptname);
my $cwd    = File::Basename::dirname($FindBin::Bin);
my $libdir = File::Spec->catdir($cwd, 'lib');

# sanity check
foreach my $expected (qw/repo var lib/) {
    die "No directory $expected found!" unless -d $expected;
}

chdir $cwd or die $!;

my $stderr = File::Spec->catfile(var => "jobs.err");
my $stdout = File::Spec->catfile(var => "jobs.log");
my $pidfile = File::Spec->catfile(var => "jobs.pid");

my $action = $ARGV[0] || 'start';

if ($action eq 'start') {
    p_start();
}
elsif ($action eq 'restart') {
    p_start();
}
elsif ($action eq 'stop') {
    p_stop();
}
else {
    die "Usage $0 [ start | stop | restart ]\n";
}

sub p_start {
    # try to stop any other running process
    p_stop();
    print "Using a poll interval of " . AMW_POLLING . " seconds\n";
    daemonize();
}

sub p_stop {
    # get the pid
    if (-f $pidfile) {
        open (my $fh, '<', $pidfile) or die $!;
        flock($fh, LOCK_EX);
        my $pid = <$fh>;
        flock($fh, LOCK_UN) or die "Cannot unlock $pidfile $!";
        close $fh;

        print "Checking PID $pid\n";
        if ($pid) {
            if (kill 0, $pid) {
                print "Jobber is alive, killing it safely";
                open (my $pfh, '>', $pidfile) or die $!;
                while (!flock($pfh, LOCK_EX | LOCK_NB)) {
                    print ".";
                    sleep 1;
                }
                print "\n";
                # now we hold the lock and we can kill the brother
                kill SIGTERM, $pid or die "Couldn't kill $pid $!";
                flock($pfh, LOCK_UN) or die "Cannot unlock $pidfile $!";
                close $pfh;
                unlink $pidfile;
                print "Removed pidfile $pidfile\n";
            }
        }
        else {
            die "Couldn't get the pid from file!";
        }
    }
}

sub daemonize {
    print "Starting jobber\n";
    nice(19);
    if ($foreground) {
        print "Working in foreground, logging to console\n";
    }
    else {
        open (STDIN, '<', File::Spec->devnull)
          or die "Couldn't open" . File::Spec->devnull;
        defined(my $pid = fork()) or die "Cannot fork: $!";
        if ($pid) {
            print "Jobber forked in the background with pid $pid\n";
            exit;
        }

        open (STDOUT, '>>:encoding(utf-8)', $stdout)
          or die "Couldn't open $stdout";
        open (STDERR, '>>:encoding(utf-8)', $stderr)
          or die "Couldn't open $stderr";
        die "Can't start a new session $!" if (setsid() == -1);
    }
    open (my $lock, '>', $pidfile) or die "Can't open pidfile $!";
    flock($lock, LOCK_EX) or die "Cannot lock $pidfile $!";
    print $lock $$;
    flock($lock, LOCK_UN) or die "Cannot unlock $pidfile $!";
    close $lock;
    main_loop();
}

sub main_loop {
    require AmuseWikiFarm::Schema;
    my $schema = AmuseWikiFarm::Schema->connect('amuse');
    my $queue = $schema->resultset('Job');
    my $count = 0;
    while (1) {
        print "sleeping...\n" if $foreground;
        sleep AMW_POLLING;
        # assert we are in the right directoy
        chdir $cwd or die $!;

        # acquire a lock on the pid file and keep until the job is over
        open (my $lock, '>', $pidfile) or die "Can't open pidfile $!";
        flock($lock, LOCK_EX) or die "Cannot lock $pidfile $!";
        print $lock $$;
        # do it
        if ($count == 0) {
            eval {
                check_and_publish_deferred($schema);
            };
            if ($@) {
                warn "Errors: $@\n";
            }
            $count++;
        }
        elsif ($count == 1000) {
            # reset the counter and trigger the deferred texts.
            $count = 0;
        }
        else {
            $count++;
        }
        if (my $job = $queue->dequeue) {
            print "Starting job on " . localtime() . "\n";
            print join(" ", "Dispatching", $job->id, $job->status, $job->task),
              "\n";
            $job->dispatch_job;
            print "Job finished on " . localtime() . "\n";
        }
        chdir $cwd or die $!;
        flock($lock, LOCK_UN);
        close $lock;
    }
}


sub check_and_publish_deferred {
    my $schema = shift;
    my $now = $schema->storage->datetime_parser->format_datetime(DateTime->now());
    print localtime() . ": checking deferred titles for $now\n";
    my @deferred = $schema->resultset('Title')
      ->search({
                status => 'deferred',
                pubdate => { '<' => $now },
               });
    foreach my $title (@deferred) {
        sleep AMW_POLLING;
        my $site = $title->site;
        my $file = $title->f_full_path_name;
        print "Publishing $file for site " . $site->id . "\n";
        $site->compile_and_index_files([ $file ]);
        print "Done\n";
    }
}
