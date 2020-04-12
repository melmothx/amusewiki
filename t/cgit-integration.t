#!perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 66;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use Digest::SHA;
use Data::Dumper::Concise;
use Email::MIME;


my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cgit0';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({
               secure_site => 0,
               pdf => 0,
              });
my $host = $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

{
    my $muse = path($site->repo_root, qw/t tt to-test.muse/);
    $muse->parent->mkpath;
    $muse->spew_utf8(<<"MUSE");
#title Test me
#lang ru
#attach shot.pdf

Все смешалось в доме Облонских. Жена узнала, что муж был в связи с
бывшею в их доме француженкою-гувернанткой, и объявила мужу, что не
может жить с ним в одном доме. Положение это продолжалось уже третий
день и мучительно чувствовалось и самими супругами, и всеми членами
семьи, и домочадцами. Все члены семьи и домочадцы чувствовали, что нет
смысла в их сожительстве и что на каждом постоялом дворе случайно
сошедшиеся люди более связаны между собой, чем они, члены семьи и
домочадцы Облонских. Жена не выходила из своих комнат, мужа третий
день не было дома. Дети бегали по всему дому, как потерянные;
англичанка поссорилась с экономкой и написала записку приятельнице,
прося приискать ей новое место; повар ушел еще вчера со двора, во
время обеда; черная кухарка и кучер просили расчета. 

[[t-t-1.png]]

[[t-t-2.jpeg]]

MUSE

    path(t => files => 'shot.pdf')->copy(path($site->repo_root, 'uploads', 'shot.pdf'));
    path(t => files => 'shot.png')->copy(path($site->repo_root, qw/t tt t-t-1.png/));
    path(t => files => 'shot.jpg')->copy(path($site->repo_root, qw/t tt t-t-2.jpeg/));
    $site->git->add('uploads');
    $site->git->add('t');
    $site->git->commit({ message => "Added files" });
}

diag "Updating DB from tree";
ok $site->remote_repo_root;
$site->update_db_from_tree;


$mech->get_ok('/');
# now we check the encoding
foreach my $url ('/git/0cgit0/tree/t/tt/to-test.muse',
                 '/git/0cgit0/plain/t/tt/to-test.muse',
                 '/git/0cgit0/commit/t/tt/to-test.muse',
                 '/git/0cgit0/diff/t/tt/to-test.muse',
                 '/git/0cgit0/diff',
                 '/git/0cgit0/commit',
                ) {
    $mech->get_ok($url);
    $mech->content_contains('Все смешалось в доме Облонских. Жена узнала, что муж был в');
}
foreach my $f ('t/tt/t-t-2.jpeg', 't/tt/t-t-1.png', 'uploads/shot.pdf') {
    $mech->get_ok('/git/0cgit0/tree/' . $f);
    $mech->get_ok('/git/0cgit0/commit/' . $f);
    $mech->get_ok('/git/0cgit0/plain/' . $f);
    my $res = $mech->response;
    diag Dumper({ $res->headers->flatten });
    ok $res->headers->header('Content-Disposition'), "$f is a download file";
    my $got_sha = Digest::SHA->new('SHA-1')->add($mech->content);
    my $src_sha = Digest::SHA->new('SHA-1')->addfile(path($site->repo_root, $f)->stringify);
    is $got_sha->hexdigest, $src_sha->hexdigest, "$f is fine";
}

$mech->get("/git/0cgit0/tree/asdfasdf");
is $mech->status, 404;
is $mech->content, ('404 Not found');
$mech->get_ok("/git");
$mech->content_contains("https://0cgit0.amusewiki.org/git/0cgit0");

my $remote = $site->remote_repo_root;
ok $remote, "Remote $remote returned";
ok $remote->exists, "Remote $remote initialized";
my $hook = $remote->child('hooks')->child('post-receive');
ok $hook->exists, "$hook exists";
like $hook->slurp_utf8, qr{/git-notify};
$mech->get_ok($site->git_notify_url);
ok !$site->initialize_remote_repo, "initialize returns false";
$site->archive_remote_repo;
ok ! -d $site->remote_repo_root, "Remote repo archived";
ok !$site->archive_remote_repo, "No op";
ok $site->initialize_remote_repo, "Initialized ok";
ok -d $site->remote_repo_root, "Remote repo OK";

my $local = Path::Tiny->tempdir(CLEANUP => 0);
my $git = Git::Wrapper->new("$local");
$git->clone($site->remote_repo_root, "$local");
diag "Using $local";
die "Not cloned" unless $local->child('.git')->exists;

PUSHING: {
    $site->jobs->delete;
    my $testfile = path($local, 'specials', 'index.muse');
    $testfile->parent->mkpath;
    $testfile->spew("#title Hello there\n\nciao\n");
    $git->add("$testfile");
    $git->commit({ message => 'Front page' });
    $git->push;
    # however, given that we're in test, the hook didn't work, so call
    # it manually.
    $mech->get_ok($site->git_notify_url);
    is $site->jobs->count, 1;
    diag Dumper($site->jobs->hri->all);
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $mech->get_ok('/special/index');
    $mech->content_contains('Hello there');
}

PULLING: {
    my ($revision) = $site->create_new_text({ uri => "new-hope",
                                              title => "A new hope",
                                              lang => 'en',
                                              textbody => "Bla bla"
                                            }, 'text');
    $revision->commit_version;
    my $file = $local->child('n')->child('nh')->child('new-hope.muse');
    my $text_id = $revision->title_id;
    ok(!$file->exists, "new file doesn't exist locally") or die;
    my $uri = $revision->publish_text;
    # now check if the revision was pushed to the shared repo
    $git->pull;
    ok($file->exists, "new file propaged") or die;
    # confirm
    $mech->get_ok($uri);

    # now add the #DELETED directive
    my $content = $file->slurp_utf8;
    $file->spew_utf8("#DELETED purge\n" . $content);
    $git->add("$file");
    $git->commit({ message => "Deleting" });
    $git->push;
    # simulate the hook
    $mech->get_ok($site->git_notify_url);

    # simulate the jobber
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $mech->get($uri);
    is $mech->status, 404;

    # now purge from the site
    $site->jobs->purge_add({
                            id => $text_id,
                            username => "pippo",
                           });
    ok($file->exists, "Local file is here") or die;
    # just one.
    if (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    # and check if the file is gone here as well
    $git->pull;
    ok(!$file->exists, "File is gone") or die;


    # now try a pull from the site
    $file->parent->mkpath;
    $file->spew_utf8("#title Test\n\nxxxx\n");
    $git->add("$file");
    $git->commit({ message => "XRestoringX" });

    $site->git->remote(add => "test", "$local");
    my $job = $site->jobs->git_action_add({
                                           remote => 'test',
                                           action => 'fetch',
                                          });
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    # and check if the change landed in the remote.
    ok scalar(grep { /XRestoringX/ } $site->shared_git->show), "Shared repo updated";
    $git->pull;
    ok scalar(grep { /XRestoringX/ } $git->show), "Shared repo updated";
}

CONFLICT: {
    $git->pull;
    my $file = $local->child('n')->child('nh')->child('new-hope.muse');
    $file->spew_utf8("#title Again\n\nxxxx\n");
    $git->add("$file");
    $git->commit({ message => "Breaking it" });
    $git->push;
    # here we don't notify the app with the hook, as it would happen.
    $site->update({
                   mail_from => 'root@amusewiki.org',
                   locale => 'en',
                   mail_notify => 'notifications@amusewiki.org',
                  });

    my ($revision) = $site->create_new_text({ uri => "bla-bla",
                                              title => "Let's break",
                                              lang => 'en',
                                              textbody => "Bla bla"
                                            }, 'text');
    $revision->commit_version;
    my $uri = $revision->publish_text;
    eval {
        $git->push;
    };
    ok $@, "Error while pushing: $@";
    $git->pull;
    diag join("\n", $git->show);
    ok scalar(grep { /^Merge:/ } $git->show), "Pulling creates a merge";
    my @emails = Email::Sender::Simple->default_transport->deliveries;
    ok (scalar @emails), "Mails sent" or die;
    my $body = shift(@emails)->{email}->as_string;
    diag $body;
    like $body, qr/Unfortunately/;
    like $body, qr/Subject: \[0cgit0.amusewiki.org\] git push shared master/;
    my $mail = Email::MIME->new($body);
    like $mail->body, qr{shared/repo/0cgit0\.git};
    like $mail->body, qr{shared/archive/archive-\d+-0cgit0\.git};
}


$mech->get('/git-notify');
is $mech->status, 404;
$mech->get('/git-notify/blabla');
is $mech->status, 403;
