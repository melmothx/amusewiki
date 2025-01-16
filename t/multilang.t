#!perl

use strict;
use warnings;
use utf8;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

plan tests => 180 + 2 * scalar(keys %{ AmuseWikiFarm::Utils::Amuse::known_langs() });

use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use File::Copy qw/copy/;
use Data::Dumper;
use Text::Amuse::Compile::Utils qw/write_file/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Lexicon;
use AmuseWikiFarm::Utils::LexiconMigration;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0multi0';
my $site = create_site($schema, $site_id);
$site->multilanguage('en it hr');
$site->update->discard_changes;

$schema->resultset('User')->update({ preferred_language => undef });

my $root = $site->repo_root;
my $filedir = catdir($root, qw/a at/);
my $specialdir = catdir($root, 'specials');
make_path($filedir);
make_path($specialdir);

die "$filedir doesn't exist" unless -d $filedir;

my @langs = (qw/en hr it/);
my @uids  = (qw/id1 id2 id3/);

my @texts;
foreach my $lang (@langs) {
    # generate the indexes
    my $index = "index-$lang";
    my $indexfilename = catfile($specialdir, $index . '.muse');
    my $body =<<"MUSE";
#title Index ($lang)
#lang $lang

This is the $lang index

MUSE
    write_file($indexfilename, $body);

    foreach my $uid (qw/id1 id2 id3/) {
        # create the muse files
        my $basename = "a-test-$uid-$lang";
        push @texts, $basename;
        my $filename = catfile($filedir, $basename . '.muse');
        my $body =<<"MUSE";
#title $lang-$uid
#uid $uid
#lang $lang
#cat geo
#author Marco

Blabla *bla* has uid $uid and lang $lang

MUSE
        write_file($filename, $body);
    }
}

$site->update_db_from_tree;


is $site->categories
  ->by_type_and_uri(qw/author marco/)
  ->titles->texts_only->by_lang('en')->count, 3,
  "Found marco's texts in english";

is $site->categories
  ->by_type_and_uri(qw/author marco/)
  ->titles->texts_only->by_lang('ru')->count, 0,
  "Found marco's texts in english";


ok $site->categories
  ->by_type_and_uri(qw/author marco/)
  ->titles->texts_only->language_stats;


use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok('/library');

$mech->get_ok('/archive');

foreach my $text (@texts) {
    $mech->content_contains($text);
}

foreach my $path ("/archive", "/topics/geo") {
    foreach my $lang (@langs) {
        $mech->get_ok("$path/$lang");
        foreach my $uid (@uids) {
            $mech->content_contains("/library/a-test-$uid-$lang");
        }
        my @others = grep { $_ ne $lang } @langs;
        foreach my $other (@others) {
            foreach my $uid (@uids) {
                $mech->content_lacks("/library/a-test-$uid-$other");
            }
        }
    }
}

foreach my $ttext (@texts) {
    my $text = $ttext;
    $mech->get_ok("/library/$text");
    $mech->content_contains("translations");
    my $others = $text;
    if ($text =~ m/^(.+-)([a-z]+)$/) {
        my $base = $1;
        my $current = $2;
        foreach my $lang (@langs) {
            next if $lang eq $current;
            $mech->content_contains("/library/$base$lang");
        }
    }
}


$mech->get("/archive/ru");
$mech->content_contains("No text found!", "No russian texts, no archive/ru");
$mech->get("/topics/geo/ru");
$mech->content_contains("No text found!");
$mech->get("/authors/marco/ru");
$mech->content_contains("No text found!");



my $text = $site->titles->find({ uri => "a-test-id2-hr" });
my @translations = $text->translations;
is (scalar(@translations), 2, "Found two translations");
foreach my $tr (@translations) {
    ok ($tr->full_uri, "Found " . $tr->full_uri);
}

my $without = $schema->resultset('Title')->find({ uri => 'second-test',
                                                  f_class => 'text',
                                                  site_id => '0blog0' });

ok($without, "Found the text");

@translations = $without->translations;
ok(!@translations, "No translations found");

my @sites = $site->other_sites;
ok(!@sites, "No related sites found");

$mech->get('/topics/geo');
$mech->content_contains('/category/topic/geo/en');
$mech->get_ok('/topics/geo?__language=it');
$mech->content_contains('/category/topic/geo/it');
$mech->content_contains('<html lang="it">');


$site->fixed_category_list("geo lines war");
$site->update->discard_changes;

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/action/text/new?__language=it');
ok($mech->form_with_fields(qw/uid title textbody/));
foreach my $cat (@{$site->list_fixed_categories}) {
    $mech->content_contains("fixed_cat_" . $cat);
    $mech->tick("fixed_cat_" . $cat, $cat);
}
$mech->field(title => "Test cat");
$mech->field(uri => "xxxx" . int(rand(1000)));
$mech->field(textbody => "Hello there");
$mech->click;

$mech->content_contains("#cat geo lines war");
$mech->form_with_fields('body');
ok($mech->click('commit'));
$mech->content_contains('Cambiamenti effettuati, ora sono in attesa di pubblicazione');

mkdir $site->path_for_site_files unless -d $site->path_for_site_files;
copy(catfile(qw/t atr-lexicon.json/), $site->lexicon_file);

ok $site->lexicon;

{
    AmuseWikiFarm::Utils::LexiconMigration::convert($site->lexicon, $site->locales_dir);
    my $model = AmuseWikiFarm::Archive::Lexicon
      ->new(
            system_wide_po_dir => path(qw/lib AmuseWikiFarm I18N/)->absolute->stringify,
            repo_dir => path("repo")->absolute->stringify,
           );
    my $lh = $model->localizer(hr => $site->id);
    is $lh->loc('geo'), 'Geografija kontrole';
    is $lh->loc('nociv'), 'Štetnosti i okolica';
    is $lh->loc('blablabla'), 'blablabla';
    $lh = $model->localizer(de => $site->id);
    is $lh->loc('spec'), 'Spezifische Kämpfe';
    $lh = $model->localizer(it => $site->id);
    is $lh->loc('nociv'), 'Nocività e dintorni';

}


$mech->get_ok('/?__language=it');
$mech->get_ok('/');
is $mech->uri->path, '/special/index-it';
$mech->content_contains('This is the it index');

my ($uri_suffixed) = $site->create_new_text({
                                           title => 'ciaoo ' x 10,
                                           author => 'pippo ' x 10,
                                           lang => "\nhr\n",
                                          }, 'text');
like $uri_suffixed->title->uri, qr/-hr$/s,
  "Long titles get the suffix for multilanguage";


my ($rev, $error) = $site->create_new_text({
                                            title => '   ',
                                            lang => 'it',
                                           }, 'text');

ok(!$rev, "no revision created");
is $error, "Couldn't automatically generate the URI!", "Error found";
$mech->get_ok('/?__language=hr');
$mech->content_contains('<html lang="hr">');
$mech->get_ok('/action/text/new');
$mech->content_like(qr/class="active"\s*id="select-lang-hr"/s);
$mech->get_ok('/?__language=it');
$mech->get_ok('/action/text/new');
$mech->content_like(qr/class="active"\s*id="select-lang-it"/s);


($rev, $error) = $site->create_new_text({
                                         title => 'x',
                                         lang => 'it',
                                         uri => 'i-have-set-the-uri-it',
                                        }, 'text');
ok (!$error, "No error") or diag $error;
is $rev->title->uri, 'i-have-set-the-uri-it',
  "No lang suffix appended when the uri is set";

foreach my $lang (sort keys %{ $site->known_langs }) {
    $mech->get_ok("/?__language=$lang");
    $mech->content_contains(qq{<html lang="$lang"});
}
$mech->get_ok("/?__language=en");
foreach my $lang (qw/alksd als jp lad/) {
    $mech->get_ok("/?__language=$lang");
    $mech->content_contains('This is the en index');
}
$mech->get_ok("/?__language=sr");
$mech->content_contains("Napravi zbirku") or diag $mech->content;
$schema->resultset('User')->update({ preferred_language => undef });


$mech->get_ok("/category/topic/geo");
$mech->content_contains('/library/a-test-id3-en');
$mech->content_contains('/library/a-test-id3-hr');
$mech->content_contains('/library/a-test-id3-it');
$mech->content_like(qr{Italiano.*3.*Hrvatski.*3.*English.*3}s);

$mech->get_ok("/category/topic/geo/it");
$mech->content_lacks(   '/library/a-test-id3-en');
$mech->content_lacks(   '/library/a-test-id3-hr');
$mech->content_contains('/library/a-test-id3-it');
$mech->content_like(qr{Italiano.*3.*Hrvatski.*3.*English.*3}s);

$mech->get_ok("/?__language=eo");
$mech->get_ok("/api/datatables-lang");

$mech->get_ok("/?__language=fa");
$mech->content_contains('dir="rtl"');
$mech->get_ok("/api/datatables-lang");

# diag $mech->content;
