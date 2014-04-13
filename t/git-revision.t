#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 9;

use AmuseWikiFarm::Schema;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Slurp qw/write_file/;
use File::Path qw/make_path remove_tree/;

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

use AmuseWikiFarm::Archive::Edit;
use AmuseWikiFarm::Archive;

my $arch = AmuseWikiFarm::Archive::Edit->new(site_schema => $site);
my $revision = $arch->create_new({ uri => 'first-test',
                                   title => 'Hello',
                                   textbody => '<p>My precious</p>',
                                 });
ok ($revision->id);

my $archive = AmuseWikiFarm::Archive->new(code => $site->id,
                                          dbic => $schema);

my $uri = $archive->publish_revision($revision->id);

ok($uri, "Publish revision returned the uri") and diag "Found $uri";

my @logs = $archive_git->log;

ok ((@logs == 3), "Found 3 commits");

like $logs[0]->message, qr/Published revision \d+/, "Log message matches";

like $logs[1]->message, qr/Imported HTML/, "Log for html ok";
