package AmuseWikiFarm::Utils::Jobber;

use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/InstanceOf Int Str/;
use Cwd;
use File::Spec;
use POSIX qw/setsid nice/;
use Fcntl qw/:flock/;
use DateTime;
use AmuseWikiFarm::Log::Contextual;

has schema => (is => 'ro',
               isa => InstanceOf['AmuseWikiFarm::Schema'],
               required => 1);

has pidfile => (is => 'ro',
                isa => Str,
                default => sub { '.amusewiki.jobber.lock' });

has polling_interval => (is => 'ro',
                         isa => Int,
                         default => sub { 5 });

has _daily => (is => 'rw', isa => Int, default => sub { 0 });
has _hourly => (is => 'rw', isa => Int, default => sub { 0 });

sub main_loop {
    my $self = shift;
    sleep $self->polling_interval;
    # wait for the lock
    $self->release_lock($self->get_lock);
    log_debug { "Acquired and released the lock" };
    my $now = time();
    if (($now - $self->_daily) > (60 * 60 * 24)) {
        $self->_daily($now);
        log_debug { "Setting daily job" };
        $self->schema->resultset('Job')->enqueue_global_job('daily_job');
    }
    if (($now - $self->_hourly) > (60 * 60)) {
        $self->_hourly($now);
        log_debug { "Setting hourly job" };
        $self->schema->resultset('Job')->enqueue_global_job('hourly_job');
    }
    my $job = eval { $self->schema->resultset('Job')->dequeue };
    if ($@) {
        log_error { "Errors on dequeu: $@" };
    }
    return unless $job;

    if (my $pid = fork()) {
        wait;
        log_info { "Detached new job " . $job->task . " " . DateTime->now } ;
        log_debug { "Child $pid exited, looping again\n" };
    }
    elsif (defined $pid) {
        # fork again
        defined(my $pid = fork()) or die "Cannot fork: $!";
        if ($pid) {
            log_debug { "Spawned jobber from $$ to $pid, exiting now" };
            exit;
        }
        $self->handle_job($job);
        exit;
    }
    else {
        die "Couldn't fork $!";
    }
}

sub handle_job {
    my ($self, $job) = @_;
    return unless $job;
    # be nice
    nice(19);
    log_info { "This is the jobber $$, detaching" };
    my $stdin = my $stdout = File::Spec->devnull;
    log_debug { "my $stdin = my $stdout  = File::Spec->devnull ($$)" };
    open (STDIN, '<', $stdin)
      or die "Couldn't open $stdin";
    open (STDOUT, '>', $stdout)
      or die "Couldn't open $stdout";
    die "Can't start a new session $!" if (setsid() == -1);
    open(STDERR, ">&STDOUT") or die "can't dup stdout: $!";

    log_info { "Starting job with pid $$" };
    my $lock = $self->get_lock;
    $self->schema->resultset('Job')->fail_stale_jobs;
    if ($job) {
        eval { $job->dispatch_job };
        if ($@) {
            log_error { "Errors: $@" };
        }
    }
    log_info { "job $$ finished, exiting" };
    $self->release_lock($lock);
}

sub get_lock {
    my $self = shift;
    my $pidfile = $self->pidfile;
    open (my $lock, '>', $pidfile) or die "Can't open $pidfile $!";
    log_debug { "Waiting for the lock on $pidfile" };
    flock($lock, LOCK_EX) or die "Cannot lock $pidfile $!";
    print $lock $$;
    return $lock;
}

sub release_lock {
    my ($self, $lock) = @_;
    flock($lock, LOCK_UN);
    close $lock;
}

1;
