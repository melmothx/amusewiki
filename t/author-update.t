#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use File::Path qw/make_path/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id =  '0authors0';

my $site = create_site($schema, $site_id);

my $repo_root = $site->repo_root;

my $text_path = catdir($repo_root, qw/a at/);
unless (-d $text_path) {
    make_path($text_path) or die $!;
}

my $body =<<'MUSE';
#title Das Recht auf Faulheit und individuelle Enteignung
#author Enrico Arrigoni
#LISTtitle Recht auf Faulheit und individuelle Enteignung
#SORTauthors Brand; Enrico Arrigoni;
#lang de
#pubdate 2014-12-18T00:50:35

Du, der du eine Arbeit hast
MUSE

$text_path = catfile($text_path, "a-test.muse");

write_file($text_path, $body);

$site->update_db_from_tree;

my $enrico = $site->categories->find({
                                      uri => 'enrico-arrigoni',
                                      type => 'author',
                                     });

is $enrico->name, 'Enrico Arrigoni', "Found the author";

$body =~ s/#SORTauthors Brand; Enrico Arrigoni;/#SORTauthors Brand; Enrico, Arrigoni;/;

write_file($text_path, $body);

$site->compile_and_index_files([$text_path]);

$enrico->discard_changes;

is $enrico->name, 'Enrico, Arrigoni', "Name updated with new compilation";
