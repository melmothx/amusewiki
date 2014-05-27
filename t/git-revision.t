#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 17;

use AmuseWikiFarm::Schema;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp qw/write_file read_file append_file/;
use File::Path qw/make_path remove_tree/;
use Data::Dumper;
use File::Temp;

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $site_id = '0gitz0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
my $archive_git = $site->git;

ok ($site);

my ($log) = $archive_git->log;

is $log->message, "Initial import\n", "Found root git revision";

ok ($site->repo_is_under_git, "db knows about git");

ok (!$schema->resultset('Site')->find('0blog0')->repo_is_under_git,
    "But blog.amusewiki is not");

diag "creating a new revision";

my ($revision, $error) =
  $site->create_new_text({ uri => 'first-test',
                           title => 'Hello',
                           lang => 'hr',
                           textbody => '<p>http://my.org My "precious"</p>',
                         }, 'text');
ok ($revision->id);

$revision->edit({
                 fix_links => 1,
                 fix_typography => 1,
                 body => $revision->muse_body,
                });
my $expected = '[[http://my.org][my.org]] My „precious”';

like $revision->muse_body, qr/\Q$expected\E/, "Correctly filtered";

my $uri = $revision->publish_text;

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
                    }, 'text');
ok ($revision->id);

$revision->edit({ body  => $revision->muse_body });

is read_file($revision->original_html,
             { binmode => ':encoding(utf-8)' }),
  qq{<p>http://my.org My "precious"</p>\n},
  "Body filtered from \r";

my $tmpfh = File::Temp->new;
my $tmpfile = $tmpfh->filename;
diag "Logging in $tmpfile";
$uri = $revision->publish_text(sub { append_file($tmpfile, @_) });
my $logged = read_file($tmpfile);

ok ($logged, "Found log: " . $logged);

ok ($uri);

@logs = $archive_git->log;

ok (@logs == 6, "Two new revisions");
like $logs[0]->message, qr/Begin editing/, "No published found";

