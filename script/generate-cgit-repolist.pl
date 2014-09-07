#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use lib 'lib';
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use Cwd;
use Getopt::Long;

my $gitpath = '/var/cache/git/';

GetOptions(gitpath => \$gitpath);

my $schema = AmuseWikiFarm::Schema->connect('amuse');

print "####### automatically generated on " . localtime() . " ######\n\n";

foreach my $site ($schema->resultset('Site')->all) {
    my $path = $gitpath . $site->id . ".git";
    unless (-d $path) {
        next;
    }
    print "repo.url=" . $site->id . "\n";
    print "repo.path=" . $path . "\n";
    print "repo.desc=" . $site->sitename . "\n";
    print "\n\n";
}

print "####### end of automatically generated config ######\n\n";
