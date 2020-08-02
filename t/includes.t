#!perl

use strict;
use warnings;
use utf8;
use Path::Tiny;
use File::Spec::Functions qw/catdir/;
use Test::More tests => 14;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use AmuseWikiFarm::Archive::BookBuilder;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0inc0');

foreach my $d ({
                sorting_pos => 0,
                directory => $site->repo_root,
               },
               {
                sorting_pos => 1,
                directory => path('t')->absolute,
               }) {
    $site->add_to_include_paths($d);
}

is_deeply $site->amuse_include_paths, [ $site->repo_root, path('t')->absolute ];

ok -d $site->repo_root;

path($site->repo_root)->child('try-another.txt')->spew_utf8(<<'MUSE');

# example
This is a configuration file

MUSE

{
    my $revision = $site->create_new_text({ uri => 'first', title => "First" }, 'text');
    $revision->edit(<<'MUSE');
#title First
#lang en

~~

#include include/try-me.muse

{{{
#include try-another.txt
}}}


MUSE
    $revision->commit_version;
    $revision->publish_text;
    my $check = qr{snippet.*configuration file}s;
    like $revision->muse_doc->as_html, $check;
    like $revision->muse_doc->as_latex, $check;
    ok scalar($revision->muse_doc->included_files);
    diag $revision->muse_doc->as_html;
    diag $revision->muse_doc->as_latex;

    my $title = $revision->title;
    unlike $title->muse_body, $check;;
    like $title->muse_body, qr{#include.*#include}s;
    like $title->html_body, $check;
    foreach my $ext (qw/html tex/) {
        my $f = $title->filepath_for_ext($ext);
        my $body = path($f)->slurp_utf8;
        like $body, $check, "$f is fine";
    }
    like path($title->filepath_for_ext('tex'))->slurp_utf8, $check;
    ok scalar($title->muse_object->included_files);
    diag Dumper([ $title->muse_object->included_files ]);
    is_deeply(
              [
               $title->muse_object->included_files
              ],
              [
               path('t/include/try-me.muse')->absolute,
               path('repo/0inc0/try-another.txt')->absolute,
              ]);
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site);
    my %opts = $bb->compiler_options;
    is_deeply $opts{include_paths}, $site->amuse_include_paths;
}




