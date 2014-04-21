#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 16;

use AmuseWikiFarm::Schema;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp qw/write_file read_file/;
use File::Path qw/make_path remove_tree/;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

if (my $stray = $schema->resultset('Site')->find('0git0')) {
    if (my $text = $stray->titles->find({ uri => 'first-test' })) {
        $text->delete;
    };
    if ( -d $stray->repo_root) {
        remove_tree($stray->repo_root);
        diag "Removed tree";
    }
    $stray->delete;
}

my $site = $schema->resultset('Site')->create({
                                               id => '0git0',
                                               locale => 'en',
                                               a4_pdf => 0,
                                               pdf => 0,
                                               epub => 0,
                                               lt_pdf => 0,
                                              })->get_from_storage;

$site->add_to_vhosts({ name => 'git.amusewiki.org' });
ok ($site);

mkdir $site->repo_root unless -d $site->repo_root;

unless (-d catdir($site->repo_root, '.git')) {
    diag "Initializing " . $site->repo_root;
    my $git = Git::Wrapper->new($site->repo_root);

    write_file(catfile($site->repo_root, "README"),
               { binmode => ':encoding(UTF-8)' },
               "test repo\n");

    $git->init;
    $git->add('.');
    $git->commit({ message => "Initial import" });
}

my $archive_git = Git::Wrapper->new($site->repo_root);

my ($log) = $archive_git->log;

is $log->message, "Initial import\n", "Found root git revision";

ok ($site->repo_is_under_git, "db knows about git");

ok (!$schema->resultset('Site')->find('0blog0')->repo_is_under_git,
    "But blog.amusewiki is not");

diag "creating a new revision";

use AmuseWikiFarm::Archive;

my ($revision, $error) =
  $site->create_new_text({ uri => 'first-test',
                           title => 'Hello',
                           lang => 'hr',
                           textbody => '<p>http://my.org My "precious"</p>',
                         });
ok ($revision->id);

$revision->edit({
                 fix_links => 1,
                 fix_typography => 1,
                 body => $revision->muse_body,
                });
my $expected = '[[http://my.org][my.org]] My „precious”';

like $revision->muse_body, qr/\Q$expected\E/, "Correctly filtered";

my $archive = AmuseWikiFarm::Archive->new(code => $site->id,
                                          dbic => $schema);



my $uri = $archive->publish_revision($revision->id);

ok($uri, "Publish revision returned the uri") and diag "Found $uri";

my @logs = $archive_git->log;

ok ((@logs == 4), "Found 4 commits");

like $logs[0]->message, qr/Published revision \d+/, "Log message matches";

like $logs[1]->message, qr/Begin editing no\.\d+/, "Log message ok";

like $logs[2]->message, qr/Imported HTML/, "Log for html ok";


($revision, $error) =
  $site->create_new_text({ uri => 'first-test-xxxxxxx',
                      title => 'Hello',
                      lang => 'hr',
                      textbody => qq{\r<p>http://my.org My "precious"</p>},
                    });
ok ($revision->id);

$revision->edit({ body  => $revision->muse_body });

is read_file($revision->original_html,
             { binmode => ':encoding(utf-8)' }),
  qq{<p>http://my.org My "precious"</p>\n},
  "Body filtered from \r";


$uri = $archive->publish_revision($revision->id);

ok ($uri);

@logs = $archive_git->log;

ok (@logs == 6, "Two new revisions");
like $logs[0]->message, qr/Begin editing/, "No published found";

