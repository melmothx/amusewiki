#!/usr/bin/env perl
use strict;
use warnings;

# core modules
use Cwd;
use File::Find;
use Data::Dumper;
use Getopt::Long;
use File::Spec::Functions qw/catdir catfile/;

# ours
use Text::Amuse::Compile;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $db = AmuseWikiFarm::Schema->connect('amuse');

foreach my $s ($db->resultset('Site')->all) {
    print $s->id . " " . $s->vhosts->single->name . "\n";
}

die "Missing repo dir!" unless -d 'repo';
chdir 'repo' or die $!;

my %options;
my @avails = (qw/epub
               html
               bare-html
               a4-pdf
               lt-pdf
               tex
               pdf
               zip/);

GetOptions (\%options,
            @avails);

print Dumper(\%options);

my %override;
if (%options) {
    foreach my $k (@avails) {
        my $real = $k;
        $real =~ s/-/_/g;
        $override{$real} = $options{$k} || 0;
    }
}

print Dumper(\%override);

if (%override) {
    if ($override{zip}) {
        $override{tex} = $override{html} = 1;
    }
    if ($override{pdf}) {
        $override{tex} = 1;
    }
}


my @todo = @ARGV;
for my $id (@todo) {
    if (-d $id) {
        my $site = $db->resultset('Site')->find($id);
        die "$id not found" unless $site;
        print "Compiling all in $id\n";
        print "Starting (" . localtime() . ")\n";
        compile_all($site);
        print "Done (" . localtime() . ")\n";
        
    }
    else {
        print "Skipping, $id not found\n";
    }
}

sub compile_all {
    my $site = shift;


    my $logfile = $site->id . ".error.log";
    my $report = sub {
        my @errors = @_;
        open (my $fh, '>>:encoding(utf-8)', $logfile) or die $!;
        print $fh @errors, "\n";
        close $fh;
    };
    $report->("starting at " . localtime() . "\n");
    my %opts = $site->compile_options;

    if (%override) {
        foreach my $k (keys %opts) {
            if (exists $override{$k}) {
                warn "Replacing $k with $override{$k}\n";
                $opts{$k} = $override{$k};
            }
        }
    }
    my $c = Text::Amuse::Compile->new(
                                      %opts,
                                      report_failure_sub => $report,
                                     );
    $Data::Dumper::Deparse = 1;
    print Dumper($c);
    my @files;
    find(sub {
             my $file = $_;
             return unless -f $file;
             return unless index($File::Find::dir, '.git') < 0;
             if ($file =~ m/\.muse$/) {
                 push @files, $File::Find::name;
             }
         }, $site->id);
    print Dumper(\@files);
    $c->compile(sort(@files));
    $report->("Ended at " . localtime() . "\n");
}
