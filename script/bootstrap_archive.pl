#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use FindBin qw/$Bin/;
use File::Basename;
use File::Find;
use File::Spec::Functions qw/catdir/;
use Data::Dumper;

use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use POSIX qw/nice/;
use Getopt::Long;

my ($refresh, $recompile, $help);

GetOptions (refresh => \$refresh,
            recompile => \$recompile,
            help => \$help,
           ) or die;

if ($help) {
    print <<"HELP";

Usage: $0 [ --refresh | --recompile | --help ] [ <site-id>, <site-id-2>, ... ]

The list of site ids is optional. If not passed, all the sites will be built.

With --help option, print this help and exit.

Without any option, bootstrap the text database and the build the
files which need compilation.

With --refresh option, same as above, but checking for outdated files
in the database first. You can save a lot of I/O.

With --recompile, the DB is just ignored, only the outdated files are
built. Handy if you want to force the rebuilding of some files.

The better strategy to force a rebuilding is to set the timestamp of
the .tex file in the past. Example to rebuild all the texts with a
pagebreak:

for i in \$(grep -l ' \(\* *\)\{5\}' */*/*.muse); do
    touch --date="2013-01-01" \$(echo \$i | sed -e 's/\.muse\$/.tex/')
done

$0 --recompile

HELP
    exit 2;
}


# be nice
nice(19);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $schema = AmuseWikiFarm::Schema->connect('amuse');

print "DB loaded, starting up\n";

my @codes;
foreach my $s ($schema->resultset('Site')->all) {
    print $s->id . " " . $s->canonical_url . "\n";
    push @codes, $s->id;
}

if (@ARGV) {
    @codes = @ARGV;
}

foreach my $code (@codes) {
    my $site = $schema->resultset('Site')->find($code);
    if ($site) {
        print "Processing $code\n";
    }
    else {
        warn "Site code $code not found in the database. Skipping...\n";
        next;
    }
    # with --refresh, just check
    if ($refresh) {
        $site->update_db_from_tree;
    }
    elsif ($recompile) {
        require Text::Amuse::Compile;
        my @files = sort keys %{ $site->repo_find_files };
        my $compiler = Text::Amuse::Compile->new($site->compile_options);
        foreach my $file (@files) {
            my $f = File::Spec->rel2abs($file, $site->repo_root);
            if ($f =~ m/\.muse$/ and $compiler->file_needs_compilation($f)) {
                $compiler->compile($f);
            }
        }
    }
    # without, do a full import
    else {
        my @files = sort keys %{ $site->repo_find_files };
        $site->compile_and_index_files(\@files);
    }
}
