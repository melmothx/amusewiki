#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 1;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;
use File::Path qw//;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0lexicon0');

my $lexdir = $site->path_for_site_files;

unless (-d $lexdir) {
    File::Path::make_path($lexdir);
}

my $json = "lasdlkflk asdlkfj alksd garbage";

write_file($site->lexicon_file, $json);

is_deeply ($site->lexicon_hashref, {});

