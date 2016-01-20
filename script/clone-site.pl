#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use File::Temp;
use YAML qw/LoadFile DumpFile/;
use Getopt::Long;
use Pod::Usage;

my $directory;

GetOptions('directory=s' => \$directory) or die;

if ($directory) {
    die "$directory is not a directory" unless -d $directory;
}

my ($action, @args) = @ARGV;

my %actions = (
               import => \&import,
               export => \&export,
              );

unless ($action && $actions{$action}) {
    pod2usage;
    exit 2;
}

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$actions{$action}->(@args);

=pod

=encoding utf8

=head1 NAME

amusewiki-clone-site

=head1 SYNOPSIS

Importing configuration, users, links, categories from files:

 amusewiki-clone-site import [ file1.yml , file2.yml, ... ]

Exporting the same to files:

 amusewiki-clone-site export [ id1, id2, id3, .... ]

When exporting, the files will be left in temporary directory. Without
arguments, all the sites will be exported.

=head2 OPTIONS

=over 4

=item --directory /path/to/dir

Accepted both by export and by import. On export, dump the files
there. On import, import all the YAML file from the specified
directory.

=back

=cut

sub import {
    my (@files) = @_;
    if ($directory) {
        opendir (my $dh, $directory) or die $!;
        push @files, map { File::Spec->catfile($directory, $_) }
          grep { /\.ya?ml$/ && -f File::Spec->catfile($directory, $_) }
          readdir $dh;
        closedir $dh;
    }
    foreach my $file (@files) {
        my $conf;
        eval { $conf = LoadFile($file) };
        if ($conf) {
            print "Importing $file\n";
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
    unless ($directory) {
        my $dir = File::Temp->newdir(CLEANUP => 0);
        $directory = $dir->dirname;
    }
    print "Using directory $directory for output\n";
    foreach my $code (@ids) {
        my $site = $schema->resultset('Site')->find($code);
        if ($site) {
            my $file = File::Spec->catfile($directory, $code . '.yaml');
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



