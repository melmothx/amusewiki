#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 2;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Path::Tiny;
use YAML qw/DumpFile/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = "0exp0";
my $site = create_site($schema, $site_id);

my $autoimport = path($site->autoimport_dir);
$autoimport->mkpath;

DumpFile($autoimport->child('categories.yml'),
         [
          {
           category_descriptions => [
                                     {
                                      lang => "en",
                                      muse_body => "[[i-1-fe-001-1-cover.png]]\n\n[[i-1-fe-001-1-fe-in-bronze.jpg]]\n",
                                     },
                                    ],
           name => "Test Me #1, November 19-December 2, 1965",
           type => "topic",
          },
         ]);

DumpFile($autoimport->child('legacy_links.yml'),
         [
          {
           legacy_path => '/?page_id=10009',
           new_path => '/library/285-august-1977-test'
          },
          {
           legacy_path => '/?page_id=10012',
           new_path => '/library/285-august-1977-new-york-new-york',
          },
          {
           legacy_path => '/?page_id=10014',
           new_path => '/library/285-august-1977-revolt-lives',
          }
         ]);
for (1, 2) {
    $site->process_autoimport_files;
}

is $site->categories->topics_only->count, 1;
is $site->legacy_links->count, 3;
