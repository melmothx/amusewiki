#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 17;
use Data::Dumper::Concise;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0mail1');
ok $site->mailer;

$site->update({ mail_from => 'root@amusewiki.org',
                locale => 'en',
                mode => 'openwiki',
                mail_notify => 'notifications@amusewiki.org',
              });

$schema->resultset('User')->search([
                                    { email => 'notifications@amusewiki.org' },
                                    { username => 'marchetto' },
                                   ])->delete;

my $user = $site->update_or_create_user({
                                         username => 'notifications',
                                         password => 'pallino',
                                         email => 'notifications@amusewiki.org',
                                         active   => 1,
                                        });
$user->set_roles([{ role => 'librarian' }]);

is $user->preferred_language, undef;


# we have 4 mails so far: newtext, commit, newuser, resetpassword


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');

$mech->get_ok('/reset-password');
ok $mech->submit_form(with_fields => { email => $user->email },
                      button => 'submit');
# first mail: reset password.

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'notifications', __auth_pass => 'pallino' });

$mech->content_contains('You are logged in now!');

$mech->get_ok('/user/create');
ok $mech->submit_form(with_fields => {
                                      username => 'marchetto',
                                      password => 'asdfasdfasdf',
                                      passwordrepeat => 'asdfasdfasdf',
                                      email => 'marchetto@amusewiki.org',
                                      emailrepeat => 'marchetto@amusewiki.org',
                                     },
                      button => 'create');
# second mail: new user

$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => "Try! for pippo",
                  textbody => "\n");
$mech->click;
$mech->content_contains('Created new text');

# third mail: text creation

$mech->submit_form(with_fields => {
                                   email => $user->email,
                                  },
                   button => 'commit');

# fourth mail: text revision

my @mails = Email::Sender::Simple->default_transport->deliveries;
is scalar(@mails), 4 or die "Expecting 4 mail";
{
    my $sent = shift @mails;
    my $recover = $sent->{email}->as_string;
    like $recover, qr{Someone, probably you, has requested a password reset for notifications};
}
{
    my $sent = shift @mails;
    my $newuser = $sent->{email}->as_string;
    like $newuser, qr{Your username is marchetto};
    diag $newuser;
}
{
    my $sent = shift @mails;
    my $newtext = $sent->{email}->as_string;
    like $newtext, qr{A new text has been created at};
    diag $newtext;
    
}
{
    my $sent = shift @mails;
    my $revision = $sent->{email}->as_string;
    like $revision, qr{A new revision has been created at};
    diag $revision;
}


#
