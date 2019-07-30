#!perl

use utf8;
use strict;
use warnings;

BEGIN {
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 57;
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

foreach my $lh ('default', 'site', 'user') {

    # reset for the loop
    $user->discard_changes->update({ reset_token => undef, reset_until => undef });
    ok !$user->reset_token, "No reset token present";
    $site->users->search({ username => 'marchetto' })->delete;


    if ($lh eq 'site') {
        $site->update({ locale => 'hr' });
    }
    elsif ($lh eq 'user') {
        $user->update({ preferred_language => 'it' });
    }
    $mech->get_ok('/');
    $mech->get_ok('/reset-password');
    ok $mech->submit_form(with_fields => { email => $user->email },
                          button => 'submit');
    # first mail: reset password.

    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => 'notifications', __auth_pass => 'pallino' });

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
    $mech->set_fields(author => 'pippo' . $lh,
                      title => "Try! for pippo",
                      textbody => "\n");
    $mech->click;
    # third mail: text creation

    $mech->submit_form(with_fields => {
                                       email => $user->email,
                                      },
                       button => 'commit');
    # fourth mail: text revision
    $mech->get_ok('/logout');
}

my @mails = Email::Sender::Simple->default_transport->deliveries;

my @expected = (
                qr{Someone, probably you, has requested a password reset for notifications},
                qr{Your username is marchetto},
                qr{A new text has been created at},
                qr{The revision has the following messages},
                # then site it set to hr
                qr{Netko, vjerojatno ti, tra=C5=BEio},
                qr{Tvoj korisnik je stvoren na},
                qr{Svrha ove poruke je da prijavi novi tekst, iako je procedura},
                qr{Izmjena sadr=C5=BEi slijede=C4=87e poruke},
                # then recipient known, with preference set
                qr{Qualcuno, probabilmente tu, ha richiesto la reimpostazione della},
                # however, the recipient is new, so we use the site locale
                qr{Tvoj korisnik je stvoren na},
                qr{Un nuovo testo =C3=A8 stato creato},
                qr{La revisione contiene i seguenti messaggi},
               );

is scalar(@mails), 12;

while (@mails) {
    my $mail = shift @mails;
    if (@expected) {
        my $exp = shift @expected;
        my $body = $mail->{email}->as_string;
        like $body, $exp;
        like $body, qr{List-Id: 0mail1\.0mail1\.amusewiki\.org}, "Found list-id identifier";
    }
    else {
        diag $mail->{email}->as_string;
    }
}
