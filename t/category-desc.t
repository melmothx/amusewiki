#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 44;

use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0catdesc0';
my $site = create_site($schema, $site_id);
$site->update({
               pdf => 0,
               multilanguage => 'en it hr',
               secure_site => 0,
              });
my ($revision) = $site->create_new_text({ uri => 'the-text',
                                          title => 'Hello',
                                          lang => 'hr',
                                          textbody => '',
                                        }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
my $uri = $revision->publish_text;
ok $uri, "Found uri $uri";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");


foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    my $full_uri = $cat->full_uri;
    ok ($cat, "Found $full_uri");
    ok ($cat->text_count, "$full_uri has " . $cat->text_count . " texts");
    $cat->category_descriptions->update_description(en => "$full_uri : this is just a *test*");
    $cat->category_descriptions->update_description(hr => "$full_uri : ovo je samo *test*");
    my $regexp_en = qr{<p>\s*\Q$full_uri\E : this is just a <em>test</em>\s*</p>}s;
    my $regexp_hr = qr{<p>\s*\Q$full_uri\E : ovo je samo <em>test</em>\s*</p>}s;
    my $desc = $cat->category_descriptions->find({ lang => 'en' });
    like $desc->html_body, $regexp_en, "found the HTML description";
    $desc = $cat->localized_desc('en');
    like $desc, $regexp_en, "localized_desc works";
    is $cat->localized_desc('it'), '', "No desc for italian";
    $mech->get_ok('/set-language?lang=en');
    $mech->get_ok($cat->full_uri);
    $mech->content_like($regexp_en, "found the HTML description");
    $mech->get_ok('/set-language?lang=it');
    $mech->get_ok($cat->full_uri);
    $mech->content_unlike($regexp_en, "HTML description");
    $mech->content_unlike($regexp_hr, "HTML description");
    $mech->get_ok('/set-language?lang=hr');
    $mech->get_ok($cat->full_uri);
    $mech->content_like($regexp_hr, "HTML description");
    $mech->content_unlike($regexp_en, "HTML description");

}

my $title = $site->titles->find({ uri => 'the-text', f_class => 'text' });
ok ($title, "Title found");
unlink $title->f_full_path_name or die $!;

$site->update_db_from_tree;

$title = $site->titles->find({ uri => 'the-text', f_class => 'text' });
ok (!$title, "Title was purged");

foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    ok ($cat, "Found " . $cat->full_uri);
    ok (!$cat->text_count, $cat->name . " should have 0 texts")
      or diag "But has " . $cat->text_count;
}


# then redo the same thing and check if the descs are still there

($revision) = $site->create_new_text({ uri => 'the-text',
                                       title => 'Hello',
                                       lang => 'hr',
                                       textbody => '',
                                     }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
$uri = $revision->publish_text;
ok $uri, "Found uri $uri";

foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    ok ($cat, "Found " . $cat->full_uri);
    ok ($cat->text_count, $cat->name . " should have 1 text")
      or diag "But has " . $cat->text_count;
}


# $site->delete;


