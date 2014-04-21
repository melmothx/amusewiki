#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 11;
use File::Path qw/make_path remove_tree/;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp qw/write_file/;
use AmuseWikiFarm::Schema;
use Git::Wrapper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

if (my $stray = $schema->resultset('Site')->find('0revs0')) {
    if ( -d $stray->repo_root) {
        remove_tree($stray->repo_root);
        diag "Removed tree";
    }
    $stray->delete;
};
my $site = $schema->resultset('Site')->create({
                                                  id => '0revs0',
                                                  locale => 'en',
                                                  a4_pdf => 0,
                                                  pdf => 0,
                                                  epub => 0,
                                                  lt_pdf => 0,
                                                  mode => 'blog',
                                                 })->get_from_storage;
$site->add_to_vhosts({ name => 'revs.amusewiki.org' });
mkdir $site->repo_root or die $!;
ok ((-d $site->repo_root), "test site created");

is ($site->staging_dirname, 'staging');

ok (-d $site->staging_dir, "Staging directory found");




# interface to create a new text

my $git = Git::Wrapper->new($site->repo_root);
unless (-d catdir($site->repo_root, '.git')) {
    diag "Initializing " . $site->repo_root;

    write_file(catfile($site->repo_root, "README"),
               { binmode => ':encoding(UTF-8)' },
               "test repo\n");

    $git->init;
    $git->add('.');
    $git->commit({ message => "Initial import" });
}

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

$revision->edit("#title blabla\n\n Hello world!\n");






