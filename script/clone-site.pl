#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use File::Temp;
use YAML qw/LoadFile DumpFile/;

my ($action, @args) = @ARGV;

my %actions = (
               import => \&import,
               export => \&export,
              );

unless ($action && $actions{$action}) {
    show_help();
    exit 2;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$actions{$action}->(@args);

sub show_help {
    print <<"HELP";
Importing configurations from files:

 $0 import [ file1.yml , file2.yml, ... ]

Exporting site configurations to files:

 $0 export [ id1, id2, id3, .... ]

When exporting, the files will be left in temporary directory. Without
arguments, all the sites will be exported.

HELP
}

sub import {
    my (@files) = @_;
    foreach my $file (@files) {
        my $conf;
        eval { $conf = LoadFile($file) };
        if ($conf) {
            $schema->resultset('Site')->deserialize_site($conf);
        }
        else {
            warn "Invalid file $file $@\n";
        }
    }
}
sub export {
    my (@ids) = @_;
    unless (@ids) {
        @ids =  map { $_->id } $schema->resultset('Site')->all;
    }
    my $dir = File::Temp->newdir(CLEANUP => 0);
    my $dirname = $dir->dirname;
    print "Using directory $dirname for output\n";
    foreach my $code (@ids) {
        my $site = $schema->resultset('Site')->find($code);
        if ($site) {
            my $file = File::Spec->catfile($dirname, $code . '.yaml');
            my $conf = $site->serialize_site;
            DumpFile($file, $conf);
            print "Exported site $code to $file\n";
        }
        else {
            warn "Site code $code not found in the database. Skipping...\n";
            next;
        }
    }
}



