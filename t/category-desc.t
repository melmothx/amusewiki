#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use Test::More tests => 13;

use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catfile catdir/;
use Text::Amuse::Compile::Utils qw/write_file/;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0catdesc0';
my $site = create_site($schema, $site_id);
$site->update({ pdf => 0 });
my ($revision) = $site->create_new_text({ uri => 'the-text',
                                          title => 'Hello',
                                          lang => 'hr',
                                          textbody => '',
                                        }, 'text');

$revision->edit("#title blabla\n#author Pippo\n#topics the cat\n\nblabla\n\n Hello world!\n");
$revision->commit_version;
my $uri = $revision->publish_text;
ok $uri, "Found uri $uri";

foreach my $uri ([qw/author pippo/],
                 [qw/topic the-cat/]) {
    my $cat = $site->categories->find({ uri => $uri->[1], type => $uri->[0] });
    ok ($cat, "Found " . $cat->full_uri);
    ok ($cat->text_count, $cat->name . " has " . $cat->text_count . " texts");
    $cat->category_descriptions->update_description(en => 'this is just a *test*');
    my $desc = $cat->category_descriptions->find({ lang => 'en' });
    like $desc->html_body, qr{<p>.*<em>test</em>.*</p>}s, "found the HTML description";
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


# then



# $site->delete;


