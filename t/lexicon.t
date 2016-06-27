#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 19;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";


use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Text::Amuse::Compile::Utils qw/write_file read_file/;
use Path::Tiny;
use JSON;
use Data::Dumper;
use AmuseWikiFarm::Utils::LexiconMigration;
use AmuseWikiFarm::Archive::Lexicon;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $id = '0lexicon0';
my $site = create_site($schema, '0lexicon0');

my $lexdir = path($site->path_for_site_files);

unless (-d $lexdir) {
    $lexdir->mkpath;
}

my $json = "lasdlkflk asdlkfj alksd garbage";

write_file($site->lexicon_file, $json);
# lazy build
is ($site->lexicon, undef);

my $locales_dir = $site->locales_dir;
diag "Path for locales is $locales_dir";
path($locales_dir)->mkpath;

$site = $schema->resultset('Site')->find($id);

my $model = AmuseWikiFarm::Archive::Lexicon->new(system_wide_po_dir => path(qw/lib AmuseWikiFarm I18N/)
                                                 ->absolute->stringify,
                                                 repo_dir => path("repo")
                                                 ->absolute->stringify);
{
    my $lh = $model->localizer(it => $site->id);
    ok !$lh->site, "No local po";
    is $lh->loc('test'), 'test';
    diag Dumper($lh);
}

write_file($site->lexicon_file, to_json({
                                         test => { it => 'Prova' },
                                         '<test>' => { it => '<Test>' },
                                         'test [_1] [_2] [_3]' => { it => '[_1] [_2] [_3] prova " ć100' },
                                        }));

$site->update_db_from_tree(sub { diag @_ });
diag "Upgraded?";
my $temp = Path::Tiny->tempdir;
foreach my $po (AmuseWikiFarm::Utils::LexiconMigration::convert($site->lexicon, $locales_dir)) {
    diag "$po";
    my $po_body = read_file($po);
    diag $po_body;
    like $po_body, qr{%1 %2 %3 prova \\" ć100};
}

{
    my $lh = $model->localizer(it => $site->id);
    ok $lh->site, "Has po";
    is ($lh->loc('test'), 'Prova') or diag Dumper($lh);
    is ($lh->loc('<test>'), '<Test>');
    is ($lh->loc('&lt;test&gt;'), '<Test>');
    is ($lh->loc('test [_1] [_2] [_3]', qw/uno due tre/), "uno due tre prova \" ć100");
    is ($lh->loc('test [_1] [_2] [_3]', [qw/uno due tre/]), "uno due tre prova \" ć100");
}

{
    my $lh = $model->localizer(hr => $site->id);
    ok (! -f $lh->local_file, $lh->local_file . " doesn't exist");
    is ($lh->loc('test'), 'test');
    $lh->local_file->spew_utf8(qq{msgid "test"\nmsgstr "Proba"\n});
    is ($lh->loc('test'), 'test');
    ok($lh->is_obsolete);
    # reload
    $lh = $model->localizer(hr => $site->id);
    diag $lh->local_file;
    is ($lh->loc('test'), 'Proba');
    sleep 1;
    $lh->local_file->spew_utf8(qq{msgid ""\nmsgstr "Content-Type: "text/plain; charset=UTF-8\\n"\n\nmsgid "test"\nmsgstr "ćxProbaX"\n});
    ok($lh->is_obsolete);
    is ($lh->loc('test'), 'Proba');
    # reload again
    $lh = $model->localizer(hr => $site->id);
    ok(!$lh->is_obsolete);
    is ($lh->loc('test'), 'ćxProbaX');
}

