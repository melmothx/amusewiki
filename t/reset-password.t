#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';    
};

use Test::More tests => 124;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0reset0');
diag $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$site->update({
               mail_from => 'root@amusewiki.org',
               locale => 'en',
               mail_notify => 'xxnotifications@amusewiki.org',
               mode => 'private',
               sitename => "Čađa",
              });
# root login and creates a user
$mech->get('/');
is $mech->status, 401;
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
if (my $user = $schema->resultset('User')->find({ username => 'sloppy' })) {
    $user->delete;
}

$mech->get_ok('/user/create');
$mech->submit_form(with_fields => {
                                   username => 'sloppy',
                                   password => 'sloppy1234',
                                   passwordrepeat => 'sloppy1234',
                                   email => 'sloppy@amusewiki.org',
                                   emailrepeat => 'sloppy@amusewiki.org',
                                  },
                   button => 'create');

my $user = $schema->resultset('User')->find({ username => 'sloppy' });
ok ($user, "Found the newly created user");
$user->roles->find({ role => 'librarian' });

{
    my @mails = Email::Sender::Simple->default_transport->deliveries;
    # diag Dumper(\@mails);
    like $mails[0]{email}->as_string, qr/sloppy1234/;
}

$mech->get('/logout');
is $mech->uri->path, '/';
is $mech->status, 401;
$mech->content_contains('__auth_user');
$mech->get_ok('/login');
$mech->content_contains('/reset-password');

{
    my ($u) = $schema->resultset('User')->set_reset_token('sloppy@amusewiki.org');
    ok $u;
    my %raw =  $u->get_columns;
    like $raw{reset_token}, qr/\{CRYPT\}\$2a\$/, "reset_token is bcrypted";
    like $raw{password}, qr/\{CRYPT\}\$2a\$/, "password is bcrypted";
    my $plain = $u->reset_token_plain;
    ok $plain and diag "Token is $plain";
    ok $schema->resultset('User')->reset_password_token_is_valid($u->username, $plain);
    ok !$schema->resultset('User')->reset_password_token_is_valid($u->username . 'x', $plain);
    ok !$schema->resultset('User')->reset_password_token_is_valid($u->username);
    ok !$schema->resultset('User')->reset_password_token_is_valid($u->username, $plain . '!');
    $u->update({ reset_until => 0 });
    ok !$schema->resultset('User')->reset_password_token_is_valid($u->username, $plain);
    $u->update({ password => 'pizza6666' });
    ok $u->get_from_storage->check_password('pizza6666');
    ok !$u->get_from_storage->check_password('pizza6666!');
    ok !$u->get_from_storage->check_password('pizza666');
}


# even if the mail doesn't exist, we print out the very same message
foreach my $try ('sloppy@amusewiki.org', 'sloppyxxxxx@amusewiki.org',
                 'root@amusewiki.org', 'lkasdfljasd', '%20') {
    $mech->get_ok('/reset-password');
    $mech->content_contains('placeholder="example@domain.tld"');
    $mech->submit_form(with_fields => { email => $try },
                       button => 'submit',
                      );
    $mech->content_contains("alert-success reset-request-sent");
    is $mech->uri->path, "/reset-password", "Path is /reset-password";
    $mech->content_lacks('placeholder="example@domain.tld"');
}
{
    my @mails = Email::Sender::Simple->default_transport->deliveries;
    is scalar(@mails), 2, "Found 2 mails";
#     3.008     2014-12-27 18:36:19-05:00 America/New_York
#         - make results of get_body be the same on Email::{Simple,MIME}
#         - ...but this method is a mess, so maybe avoid using Abstract for body
    #           work
    my $email_body = $mails[1]{email}->get_body;
    # blah.
    $email_body =~ s/=\r?\n//gs;
    my ($link) = $email_body =~ m{(https://.*?)\s*$}m;
    diag $email_body;
    diag $mails[1]{email}->get_header("Subject");
    is $mails[1]{email}->get_header("Subject"), 'Reset your password';
    ok $link, "Found reset link" and diag $link;

    {
        my $wrong_link = $link;
        $wrong_link =~ s/sloppy/root/;
        my $short_link = $link;
        chop($short_link);
        foreach my $l ($wrong_link, $link . "!", $short_link) {
            $mech->get_ok($l);
            is ($mech->uri->path, '/reset-password', "Bounced back");
            $mech->content_contains('invalid or expired', "$l bounces back");
        }
    }

    $mech->get_ok($link);
    is $mech->uri->as_string, $link;

    my $new_password = 'prova1234';
    foreach my $bad (['', ''], # empty
                     ['prova', 'prova'], # too short
                     ['', $new_password ],
                     [ $new_password, '' ],
                     [ $new_password . '!' , $new_password ]) {
        ok $mech->submit_form(with_fields => {
                                              password => $bad->[0],
                                              passwordrepeat => $bad->[1],
                                             });
        is $mech->uri->as_string, $link;
    }
    ok $mech->submit_form(with_fields => {
                                          password => $new_password,
                                          passwordrepeat => $new_password,
                                         });
    is $mech->uri->path, '/login';

    $mech->get_ok($link);

    is ($mech->uri->path, '/reset-password', "Bounced back");
    $mech->content_contains('expired', "$link bounces back after being consumed");

    $mech->get('/latest');
    $mech->submit_form(with_fields => { __auth_user => 'sloppy', __auth_pass => $new_password });
    is $mech->uri->path, '/latest', "Login ok with new password";
    $mech->get('/logout');

    is $mech->uri->path, '/';
    is $mech->status, 401;
    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => 'sloppy', __auth_pass => 'sloppy1234' });
    is $mech->uri->path, '/login', "Couldn't login with wrong password";
    $mech->get('/reset-password/sloppy/');
    # the catchall route is plugged into the auth, so we never get a
    # 404 before a 401. Which is a good thing, probably
    is $mech->status, '401';
    foreach my $fake ('%20', 0, 'asldfasd', 'asdfasdfasdf') {
        $mech->get("/reset-password/sloppy/$fake");
        is $mech->uri->path, '/reset-password', "Invalid tokens";
    }
}

$schema->resultset('User')->search({ username => { -like => 'pallinox%' }})->delete;

for (1..3) {
    my $user = $schema->resultset('User')->create({ username => "pallinox$_",
                                                    password => "pallino",
                                                    email => 'pallino@amusewiki.org' });
    $site->add_to_users($user);
}
{
    my @users = $site->users->set_reset_token('pallino@amusewiki.org');
    is scalar(@users), 3, "Found 3 users";
    foreach my $user (@users) {
        ok($user->reset_token) and diag $user->reset_token;
    }
    my @repeat = $site->users->set_reset_token('pallino@amusewiki.org');
    sleep 1;
    ok (@repeat, "got repeating the request");
    foreach my $user (@repeat) {
        ok $user->reset_token_plain;
        ok $site->users->reset_password_token_is_valid($user->username,
                                                       $user->reset_token_plain);
        $mech->get_ok(join('/', '/reset-password', $user->username, $user->reset_token_plain));
        $mech->submit_form(with_fields => {
                                           password => 'PASSWORD',
                                           passwordrepeat => 'PASSWORD',
                                          });
        ok $user->get_from_storage->check_password('PASSWORD');
    }
    # checking cleanup
    @users = $site->users->search({ email => 'pallino@amusewiki.org' });
    foreach my $user (@users) {
        ok $user->reset_token, "Token still here for " . $user->username;
        ok !$user->reset_until, "Timestamp cleared for " . $user->username;
    }

    diag "Generating token and tweaking timestamp";
    @users = $site->users->set_reset_token('pallino@amusewiki.org');
    foreach my $user (@users) {
        ok $user->reset_token, "Token generated for " . $user->username;
        ok $user->reset_until, "Timestamp generated for " . $user->username;
    }
    $site->users->search({ email => 'pallino@amusewiki.org' })
      ->update({ reset_until => time() - 1 });
    foreach my $user (@users) {
        ok (!$site->users->reset_password_token_is_valid($user->username, $user->reset_token_plain),
            "Expired token " . $user->username . $user->reset_token_plain);
    }

    @users = $site->users->set_reset_token('pallino@amusewiki.org');
    sleep 1;
    foreach my $user (@users) {
        ok $user->reset_token, "Token generated for " . $user->username;
        ok $user->reset_until > time(), "Timestamp generated for " . $user->username;
    }
}

is ($site->users->count, 4, "Four users found");

