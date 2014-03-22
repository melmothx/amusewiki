#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";


use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Queue;
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
my $queue = AmuseWikiFarm::Archive::Queue->new(dbic => $schema);

my $cwd = getcwd();
my $jobdir = File::Spec->catdir($cwd, 'root', 'custom');

print "Starting job server loop in $cwd\n";

while (1) {
    do_the_job();
    sleep 3;
}


sub do_the_job {
    chdir $cwd or die $!;
    my $job = $queue->get_job;
    return unless $job;
    if ($job->task eq 'bookbuilder') {
        my $output;
        eval {
            $output = bookbuilder($job);
        };
        if (!$@ && $output) {
            $job->completed(DateTime->now);
            $job->status('completed');
            $job->produced($output);
        }
        else {
            $job->status('failed');
            $job->errors($@);
        }
    }
    else {
        $job->status('pending');
    }
    $job->update;
}

sub bookbuilder {
    my $j = shift;
    my $data = from_json($j->payload);

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
    unless (@texts) {
        $j->errors('No text found!');
        $j->status('Rejected');
        return;
    }

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

    my $compiler = Text::Amuse::Compile->new(
                                             tex => 1,
                                             pdf => 1,
                                             extra => $template_opts,
                                            );
#    if (@texts == 1) {
#        $compiler->compile($texts[0] . '.muse');
#    }

    my $target = {
                  path => $basedir,
                  files => \@texts,
                  name => $j->id,
                  title => $data->{title},
                 };

    # compile
    $compiler->compile($target);

    my $outfile = $j->id . '.pdf';
    die "$outfile not produced!" unless (-f $outfile);

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
    return $outfile;
}
