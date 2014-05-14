#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 17;
use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp qw/write_file/;
use AmuseWikiFarm::Schema;
use Git::Wrapper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0revs0';
my $git = create_site($schema, '0revs0');
my $site = $schema->resultset('Site')->find($site_id);

ok ((-d $site->repo_root), "test site created");
is ($site->staging_dirname, 'staging');
ok (-d $site->staging_dir, "Staging directory found");


# interface to create a new text
my ($log) = $git->log;

is $log->message, "Initial import\n", "Found root git revision";

# the interface should be

my $revision = $site->create_new_text({ uri => 'first-testx',
                                        title => 'Hello',
                                        lang => 'hr',
                                        textbody => '<p>http://my.org My "precious"</p>',
                                      });

ok ($revision->id, "Found the revision id");

ok -f ($revision->f_full_path_name),
  "Text stored in " . $revision->f_full_path_name;

ok (-f $revision->starting_file, "Original body was stored");

ok $revision->publish_text;

my $published = $site->titles->published_texts->find({ uri => 'first-testx' });
ok($published, "Text is published");

$revision = $published->new_revision;

ok -f ($revision->f_full_path_name),
  "Text stored in " . $revision->f_full_path_name;
ok (-f $revision->starting_file, "Original body was stored");

$revision->edit("#title blabla\n#notes blabla\n\n Hello world!\n");

my $uri = $revision->publish_text;

ok $uri, "Found uri $uri";

my $text = $site->titles->published_texts->find({ uri => $uri});

ok ($text, "Found text as published");

ok ($text->notes, "Found the notes");

$revision = $text->new_revision;
$revision->edit("#title blabla\n\n Hellox worldx!\n");
is $uri, $revision->publish_text, "New revision published";
$text = $site->titles->published_texts->find({ uri => $uri});
like $text->html_body, qr/Hellox worldx/, "Found updated html body";

ok !$text->notes, "Notes are empty" or diag "Found " . $text->notes;
