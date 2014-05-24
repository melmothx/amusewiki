#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";


use AmuseWikiFarm::Schema;
use JSON qw/from_json/;
use Data::Dumper;
use File::Temp;
use File::Copy;
use File::Spec;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Cwd;
use Text::Amuse::Compile;
use PDF::Imposition;
use DateTime;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $queue = $schema->resultset('Job');

my $cwd = getcwd();
my $jobdir = File::Spec->catdir($cwd, 'root', 'custom');

print "Starting job server loop in $cwd\n";

my %handlers = (
                bookbuilder => \&bookbuilder,
                publish     => \&publish,
                git        => \&git_actions,
               );

while (1) {
    chdir $cwd or die $!;
    sleep 3;
    my $job = $queue->dequeue;
    next unless $job;
    print "Dispatching " . $job->id;
    print $job->status, " => ", $job->task, "\n";
    print Dumper(\%handlers);
    if (my $handler = $handlers{$job->task}) {
        my $output;
        eval {
            $output = $handler->($job);
        };
        if ($@) {
            $job->status('failed');
            $job->errors($@);
        }
        else {
            $job->completed(DateTime->now);
            $job->status('completed');
            $job->produced($output);
        }
    }
    else {
        print "No handler found for " . $job->task . "\n";
        $job->status('pending');
    }
    chdir $cwd or die $!;
    $job->update;
}

sub publish {
    my $j = shift;
    my $data = from_json($j->payload);
    print Dumper($data);
    $schema->resultset('Revision')->find($data->{id})->publish_text($j->logger);
}

sub git_actions {
    my $j = shift;
    my $data = from_json($j->payload);
    my $logger = $j->logger;
    print Dumper($data);
    my $site = $j->site;
    my $remote = $data->{remote};
    my $action = $data->{action};
    my $validate = $j->site->remote_gits_hashref;
    die "Couldn't validate" unless $validate->{$remote}->{$action};
    if ($action eq 'fetch') {
        $j->site->repo_git_pull($remote, $logger);
        $j->site->update_db_from_tree($logger);
    }
    elsif ($action eq 'push') {
        $j->site->repo_git_push($remote, $logger);
    }
    else {
        die "Unhandled action!";
    }
    return 1;
}


# TODO this one should be moved in Archive::BookBuilder, or in
# archive, so it should know how to handle the options. It also lacks
# testing, but appears good
sub bookbuilder {
    my $j = shift;
    my $data = from_json($j->payload);
    my $logger = $j->logger;
    print Dumper($data);
    # first, get the text list
    my $textlist = $data->{text_list};

    print $j->site->id, "\n";

    my %compile_opts = $j->site->compile_options;
    my $template_opts = $compile_opts{extra};

    # overwrite the site ones with the user-defined (and validated)
    foreach my $k (keys %{ $data->{template_options} }) {
        $template_opts->{$k} = $data->{template_options}->{$k};
    }

    print Dumper($template_opts);

    my $bbdir    = File::Temp->newdir(CLEANUP => 0);
    my $basedir = $bbdir->dirname;

    print "Created $basedir\n";

    my %archives;

    # validate the texts passed looking up the uri in the db
    my @texts;
    foreach my $text (@$textlist) {
        my $title = $j->site->titles->by_uri($text);
        next unless $title;

        push @texts, $text;
        if ($archives{$text}) {
            next;
        }
        else {
            $archives{$text}++;
        }

        # pick and copy the zip in the temporary dir
        my $zip = $title->filepath_for_ext('zip');
        if (-f $zip) {
            copy($zip, $basedir) or die $!;
        }
    }
    die "No text found!" unless @texts;

    chdir $basedir;
    # extract the archives
    foreach my $i (keys %archives) {
        my $zipfile = $i . '.zip';
        my $zip = Archive::Zip->new;
        unless ($zip->read($zipfile) == AZ_OK) {
            warn "Couldn't read $i.zip";
            next;
        }
        $zip->extractTree($i);
        undef $zip;
        unlink $zipfile or die $!;
    }
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, @_;
    };
    my $compiler = Text::Amuse::Compile->new(
                                             tex => 1,
                                             pdf => 1,
                                             extra => $template_opts,
                                             logger => $logger,
                                            );
    print $compiler->version;

    my $outfile = $j->id . '.pdf';

    if (@texts == 1) {
        my $basename = shift(@texts);
        my $pdfout   = $basename . '.pdf';
        $compiler->compile($basename . '.muse');
        if (-f $pdfout) {
            move($pdfout, $outfile);
        }
    }
    else {
        my $target = {
                      path => $basedir,
                      files => \@texts,
                      name => $j->id,
                      title => $data->{title},
                     };
        # compile
        $compiler->compile($target);
    }

    die "$outfile not produced!\n" unless (-f $outfile);

    # imposing needed?
    if ($data->{imposer_options} and %{$data->{imposer_options}}) {

        my %args = %{$data->{imposer_options}};
        $args{file}    =  $outfile;
        $args{outfile} = $j->id. '.imp.pdf';
        $args{suffix}  = 'imp';
        my $imposer = PDF::Imposition->new(%args);
        $imposer->impose;
        # overwrite the original pdf, we can get another one any time
        copy($imposer->outfile, $outfile);
    }
    copy($outfile, $jobdir);
    if (@warnings) {
        $logger->(@warnings);
    }
    return $outfile;
}
