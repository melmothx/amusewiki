#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 'lib';
use URI;
# use AmuseWikiFarm::Schema;
use Data::Dumper;
$Data::Dumper::Sortkeys =1;
use XML::RSS::LibXML;
use Text::Amuse::Preprocessor::HTML qw/html_to_muse/;
binmode STDOUT, ':encoding(UTF-8)';

my ($site_id, $file) = @ARGV;
die unless $site_id && $file;
my $feeder = XML::RSS::LibXML->new;
$feeder->parsefile($file);
my @feeds = $feeder->items;
my $max = 100;
my $count = 0;
my $last;
foreach my $entry (@feeds) {
    my $meta = $entry->{wp};
    if ($meta->{post_type} eq 'post' and $meta->{post_type} eq 'post') {
        my $body = $entry->{content}->{encoded};
        $body =~ s/\r?\n/<p \/>/g;
        my @links;
        foreach my $name (qw/link guid/) {
            if (my $v = $entry->{$name}) {
                push @links, "$v";
            }
        }
        my $muse = html_to_muse($body);
        $muse =~ s/\]\[\]\]/]]/g;
        print "\n$muse\n";
    }
}

