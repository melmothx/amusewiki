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
use AmuseWikiFarm::Log::Contextual;
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
        print "Waiting to get a lock on $pidfile...\n";
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
        sleep AMW_POLLING;
        # assert we are in the right directoy
        chdir $cwd or die $!;

        # acquire a lock on the pid file and keep until the job is over
        open (my $lock, '>', $pidfile) or die "Can't open pidfile $!";
        flock($lock, LOCK_EX) or die "Cannot lock $pidfile $!";
        print $lock $$;
        # do it
        if ($count == 0) {
            if (my $jobpid = fork()) {
                log_debug { "Forked pid $jobpid" };
                my $ex_job_pid = wait;
                log_debug { "Pid exited $ex_job_pid" };
            }
            elsif (defined $jobpid) {
                eval {
                    check_and_publish_deferred($schema);
                    purge_jobs_and_revisions($schema);
                };
                if ($@) {
                    log_error { "Errors: $@" };
                }
                exit;
            }
            else {
                die "Couldn't fork!";
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
            log_info { "Starting job on " . localtime() };
            log_info { join(" ", "Dispatching", $job->id, $job->status, $job->task) };
            if (my $jobpid = fork()) {
                log_info { "Job forked as $jobpid" };
                my $ex_job_pid = wait;
                log_info { "Job $ex_job_pid exited" };
            }
            elsif (defined $jobpid) {
                $job->dispatch_job;
                exit;
            }
            else {
                die "Couldn't fork!";
            }
            log_info { "Job finished on " . localtime() };
        }
        chdir $cwd or die $!;
        flock($lock, LOCK_UN);
        close $lock;
    }
}


sub check_and_publish_deferred {
    my $schema = shift;
    my $now = DateTime->now;
    log_debug { localtime() . ": checking deferred titles for $now" };
    my $deferred = $schema->resultset('Title')->deferred_to_publish($now);
    while (my $title = $deferred->next) {
        sleep AMW_POLLING;
        my $site = $title->site;
        my $file = $title->f_full_path_name;
        log_info { "Publishing $file for site " . $site->id };;
        $site->compile_and_index_files([ $file ]);
        log_info { "Done publishing $file" };
    }
}

sub purge_jobs_and_revisions {
    my $schema = shift;
    my $reftime = DateTime->now;
    # after one month, delete the revisions and jobs
    $reftime->subtract(months => 1);
    my $old_revs = $schema->resultset('Revision')->published_older_than($reftime);
    while (my $rev = $old_revs->next) {
        die unless $rev->status eq 'published'; # this shouldn't happen
        log_warn { "Removing published revision " . $rev->id . " for site " .
                     $rev->site->id . " and title " . $rev->title->uri };
        $rev->delete;
    }
    my $old_jobs = $schema->resultset('Job')->completed_older_than($reftime);
    while (my $job = $old_jobs->next) {
        die unless $job->status eq 'completed'; # shouldn't happen
        log_warn { "Removing old job " . $job->id . " for site " . $job->site->id .
                     " and task " . $job->task };
        $job->delete;
    }
}
