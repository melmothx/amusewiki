#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 5;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file/;
use File::Path qw//;
use JSON;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $id = '0lexicon0';
my $site = create_site($schema, '0lexicon0');

my $lexdir = $site->path_for_site_files;

unless (-d $lexdir) {
    File::Path::make_path($lexdir);
}

my $json = "lasdlkflk asdlkfj alksd garbage";

write_file($site->lexicon_file, $json);
# lazy build
is ($site->lexicon, undef);



$site = $schema->resultset('Site')->find($id);
write_file($site->lexicon_file, to_json({
                                         test => { it => 'Prova' },
                                         '<test>' => { it => '<Test>' },
                                         'test [_1] [_2] [_3]' => { it => '[_1] [_2] [_3] prova' },
                                        }));

is ($site->lexicon_translate(it => 'test'), 'Prova');
is ($site->lexicon_translate(it => '<test>'), '<Test>');
is ($site->lexicon_translate(it => '&lt;test&gt;'), undef);
is ($site->lexicon_translate(it => 'test [_1] [_2] [_3]', qw/uno due tre/),
    "uno due tre prova");


