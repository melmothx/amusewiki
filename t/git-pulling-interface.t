#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 14;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
}

use Data::Dumper;
use File::Path qw/make_path remove_tree/;
use Text::Amuse::Compile::Utils qw/write_file/;
use Git::Wrapper;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy::Recursive qw/dircopy/;
use File::Copy qw/copy/;

use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use constant { DEBUG => 0 };


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0pull3';
my $site = create_site($schema, $site_id);
$site->update({
               mail_from => 'test@amusewiki.org',
               secure_site => 0,
               locale => 'en',
               mail_notify => 'test@amusewiki.org',
              });
my $git = $site->git;
ok ((-d $site->repo_root), "test site created");


ok $site->mail_notify;
ok $site->mail_from;

my $remotegit = Path::Tiny->tempdir(CLEANUP => 0);
my $remote = Git::Wrapper->new("$remotegit");
my $testfile = path($remotegit, 'specials', 'index.muse');
{
    $remote->clone($site->repo_root, "$remotegit");
    diag "Cloned in $remotegit?";
    die "Not cloned" unless $remotegit->child('.git')->exists;
    $testfile->parent->mkpath;
    $testfile->spew("#title Hello\n\nciao\n");
    $remote->add("$testfile");
    $remote->commit({ message => 'First addition' });
}

$site->git->remote(add => test => "$remotegit");

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/login');
$mech->submit_form(with_fields => {
                                   __auth_user => 'root',
                                   __auth_pass => 'root',
                                  });
my $bulk_job_page;
{
    my $job = $site->jobs->git_action_add({ remote => 'test',
                                            action => 'fetch' });
    ok $job->dispatch_job;
    $bulk_job_page = $job->produced;
}

ok($bulk_job_page, "Fetching bulk page job") or die;
$mech->get_ok($bulk_job_page . '?bare=1');
diag $mech->content;

$mech->content_like(qr{class="job-started">[^<>]*UTC</span>});

while (my $job = $site->jobs->dequeue) {
    $job->dispatch_job;
}

$mech->get_ok($bulk_job_page . '?bare=1');
diag $mech->content;
$mech->content_like(qr{class="job-started">[^<>]*UTC</span>});
$mech->content_like(qr{class="job-completed">[^<>]*UTC</span>});
$mech->content_like(qr{class="job-eta">[^<>]*UTC</span>});
ok($site->cgit_base_url) and diag $site->cgit_base_url;
diag "Checkin mails";

# check just the first.
my ($mail) =  Email::Sender::Simple->default_transport->deliveries;
if ($mail) {
    my $url = $site->cgit_base_url . '/commit/?id=3D';
    like $mail->{email}->as_string, qr{^URL: \Q$url\E[0-9a-f]+}m;
}


