#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 137;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use File::Path qw/make_path/;
use File::Copy qw/copy/;
use Data::Dumper;
use Text::Amuse::Compile::Utils qw/write_file/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0multi0';
my $site = create_site($schema, $site_id);
$site->multilanguage('en it hr');
$site->update->discard_changes;

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
$mech->content_contains('/topics/geo/en');
$mech->get_ok('/set-language?lang=it&goto=%2Ftopics%2Fgeo');
$mech->content_contains('/topics/geo/it');

$site->fixed_category_list("geo lines war");
$site->update->discard_changes;

$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');
$mech->get_ok('/action/text/new');
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

ok $site->lexicon_hashref;

# print Dumper($site->lexicon_hashref);
is $site->lexicon_translate(hr => 'geo'), 'Geografija kontrole';
is $site->lexicon_translate(hr => 'blablabla'), 'blablabla';

$mech->get_ok('/set-language?lang=it');
$mech->get_ok('/');
$mech->content_contains('This is the it index');

my $uri_suffixed = $site->create_new_text({
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
is $error, "Couldn't generate the uri!", "Error found";
