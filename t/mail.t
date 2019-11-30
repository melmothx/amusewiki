#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 73;
use AmuseWikiFarm::Utils::Mailer;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Git::Wrapper;
use Path::Tiny;

my $mailer = AmuseWikiFarm::Utils::Mailer->new(mkit_location => 't/mkits');

ok($mailer);

{
    my $exit = $mailer->send_mail(test => {
                                           from => "Mić <me\@localhost>",
                                           to => "Mać <me\@localhost>",
                                           cc => '',
                                           subject => 'testè',
                                           test => 'Mić Mać Đoè'
                                          });
    ok($exit, "Deliver ok");
}
{
    my $exit = $mailer->send_mail(test => {
                                           from => "Mić <me\@localhost>",
                                           to => "Mać <me\@localhost>",
                                           cc => '',
                                           subject => 'testè',
                                          });
    ok(!$exit, "Deliver not ok");
}


my $site_id = '0mail0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->update({ mail_from => 'root@amusewiki.org',
                locale => 'en',
                mail_notify => 'xnotifications@amusewiki.org',
              });

my $user = $site->update_or_create_user({
                                         username => 'mailer',
                                         password => 'pallino',
                                         email => 'pallino@amusewiki.org',
                                         active   => 1,
                                        });
$user->set_roles([{ role => 'librarian' }]);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");


$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'mailer', __auth_pass => 'pallino' });
$mech->get_ok('/user/create');

$schema->resultset('User')->search({ username => 'newmailer' })->delete;
$mech->submit_form(with_fields => {
                                   username => 'newmailer',
                                   password => 'pazzXXXXXXXXXXXXX',
                                   passwordrepeat => 'pazzXXXXXXXXXXXXX',
                                   email => 'newmailer@amusewiki.org',
                                   emailrepeat => 'newmailer@amusewiki.org',
                                  },
                   button => 'create',
                  );

$mech->get_ok('/logout');
$user->update({ email => '' });
$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'mailer', __auth_pass => 'pallino' });
$mech->get_ok('/user/create');
$schema->resultset('User')->search({ username => 'newmailer' })->delete;
$mech->submit_form(with_fields => {
                                   username => 'newmailer',
                                   password => 'pazzXXXXXXXXXXXXX',
                                   passwordrepeat => 'pazzXXXXXXXXXXXXX',
                                   email => 'newmailer@amusewiki.org',
                                   emailrepeat => 'newmailer@amusewiki.org',
                                  },
                   button => 'create',
                  );

$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => 'My test',
                  textbody => "Hello world\n");
$mech->click;
$mech->form_id('museform');
$mech->click("commit");

$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => '*My* **test** & 2',
                  textbody => "Hello world again\n");
$mech->click;
$mech->form_id('museform');
$mech->set_fields(email => 'uploader@amusewiki.org',
                  attachment => 't/files/shot.png');
$mech->click("commit");

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

{
    my $job = $site->jobs->git_action_add({ remote => 'test',
                                            action => 'fetch' });

    diag $job->dispatch_job;
}

foreach my $rev ($site->revisions) {
    ok $rev->publish_text;
}

{
    $mech->get_ok('/library/pippo-my-test-2/edit');
    $mech->form_id('museform');
    $mech->set_fields(email => 'uploader@amusewiki.org',
                      attachment => 't/files/shot.png'
                     );
    $mech->click("commit");
}

$site->update({ mail_from => undef });
# no mail;

{
    $testfile->spew("#title Hello\n\nciao\nciao\nciao\n");
    $remote->add("$testfile");
    $remote->commit({ message => 'Second addition' });

}

{
    my $job = $site->jobs->git_action_add({ remote => 'test',
                                            action => 'fetch' });

    diag $job->dispatch_job;
}

{
    my @mails = Email::Sender::Simple->default_transport->deliveries;
    is scalar(@mails), 11, "mails sent" or die Dumper(\@mails);
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "Email sent") and diag $sent->{email}->as_string;
        my $body = $sent->{email}->as_string;
        ok ($body);
        like ($body, qr/Hello there Mi=C4=87 Ma=C4=87 =C4=90o=C3=A8/);
        like ($body, qr/To: =\?UTF-8\?B\?TWHEhw==\?= <me\@localhost>/);
        like ($body, qr/From: =\?UTF-8\?B\?TWnEhw==\?= <me\@localhost>/);
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        diag $body;
        like $body, qr{cc: pallino\@amusewiki.org}i;
        like $body, qr{subject: User created}i;
        like $body, qr{newmailer.*pazzXXXXXXXXXXXXX}s, "Email body has username and pass";
        is_deeply $sent->{successes}, ['newmailer@amusewiki.org',
                                       'pallino@amusewiki.org' ];
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        diag $body;
        like $body, qr{subject: User created}i;
        like $body, qr{newmailer.*pazzXXXXXXXXXXXXX}s, "Email body has username and pass";
        unlike $body, qr{cc: pallino\@amusewiki.org}i;
        is_deeply $sent->{successes}, ['newmailer@amusewiki.org' ];
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail on new text");
        my $body = $sent->{email}->as_string;
        ok ($body);
        $body =~ s/=\r?\n//g;
        like $body, qr{subject: /library/pippo-my-test}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test/};
        like $body, qr{needs to finalize the upload}i;
        diag $body;
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        like $body, qr{subject: /library/pippo-my-test}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test/[0-9]+/diff};
        like $body, qr{Preview};
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test/[0-9]+/preview};
        unlike $body, qr{cc: uploader\@amusewiki.org}i;
        diag $body;
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail on new text");
        my $body = $sent->{email}->as_string;
        ok ($body);
        $body =~ s/=\r?\n//g;
        like $body, qr{subject: /library/pippo-my-test-2}i;
        like $body, qr{needs to finalize the upload}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test-2/};
        diag $body;
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        like $body, qr{changes for pippo-my-test-2}i;
        like $body, qr{subject: /library/pippo-my-test-2}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test-2/};
        like $body, qr{cc: uploader\@amusewiki.org}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test-2/p-m-pi},
          "Found attachment";
        diag $body;
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        like $body, qr{specials/index\.muse}i;
        like $body, qr{subject: \[0mail0\.amusewiki\.org\] git pull test}i;
        like $body, qr{https\:\/\/0mail0\.amusewiki\.org\/tasks\/job\/};
        diag $body;
    }
    # the two status changed mails
    if (@mails and my $sent = shift @mails) {
        my $body = $sent->{email}->as_string;
        like $body, qr{status changed}i;
    }
    if (@mails and my $sent = shift @mails) {
        my $body = $sent->{email}->as_string;
        like $body, qr{status changed}i;
    }
    if (@mails and my $sent = shift @mails) {
        ok ($sent, "The application sent the mail");
        my $body = $sent->{email}->as_string;
        ok ($body);
        like $body, qr{changes for.*my test & 2}i;
        like $body, qr{subject: /library/pippo-my-test-2}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test-2/};
        like $body, qr{cc: uploader\@amusewiki.org}i;
        like $body, qr{https://0mail0.amusewiki.org/action/text/edit/pippo-my-test-2/p-m-pi},
          "Found attachment";
        diag $body;
    }


}
