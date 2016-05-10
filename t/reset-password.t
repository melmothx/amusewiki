#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';    
};

use Test::More tests => 94;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0reset0p');
diag $site->canonical;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$site->update({
               mail_from => 'root@amusewiki.org',
               locale => 'en',
               mail_notify => 'notifications@amusewiki.org',
               mode => 'private',
              });
# root login and creates a user
$mech->get_ok('/');
is $mech->uri->path, '/login';
$mech->submit_form(with_fields =>  {
                                    username => 'root',
                                    password => 'root',
                                   },
                   button => 'submit');

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

$mech->get_ok('/logout');
$mech->get_ok('/login');
$mech->content_contains('/reset-password');

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
    like $mails[1]{email}->get_header("Subject"), qr/Password reset for/;
    ok $link, "Found reset link" and diag $link;

    my $wrong_link = $link;
    $wrong_link =~ s/sloppy/root/;
    $mech->get($wrong_link);
    is $mech->status, '403';

    $mech->get_ok($link);
    is $mech->uri . '' , $link;
    my ($new_password) = $mech->content =~ m{<span class="new-password"><code>(.+)</code>};
    ok ($new_password, "Found the new password $new_password");
    $mech->get($link);
    is $mech->status, '403', "Access denied with token consumed" or diag $mech->content;
    $mech->get_ok('/');
    is $mech->uri->path, '/login';
    $mech->submit_form(with_fields =>  {
                                        username => 'sloppy',
                                        password => $new_password,
                                       },
                       button => 'submit');
    is $mech->uri->path, '/library', "Login ok with new password";
    $mech->get_ok('/logout');
    $mech->get_ok('/login');
    $mech->submit_form(with_fields =>  {
                                        username => 'sloppy',
                                        password => 'sloppy1234',
                                       },
                       button => 'submit');
    is $mech->uri->path, '/login', "Couldn't login with new password";
    $mech->get('/reset-password/sloppy/');
    # the catchall route is plugged into the auth, so we never get a
    # 404 before a 401. Which is a good thing, probably
    is $mech->status, '401';
    foreach my $fake ('%20', 0, 'asldfasd', 'asdfasdfasdf') {
        $mech->get("/reset-password/sloppy/$fake");
        is $mech->status, '403', "Access denied on " . $mech->uri->path;
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
    ok (!@repeat, "no users got repeating the request");
    foreach my $user (@users) {
        my $new_password = $site->users->reset_password($user->username,
                                                        $user->reset_token);
        ok ($new_password) and diag "New password is $new_password";
    }
    # checking cleanup
    @users = $site->users->search({ email => 'pallino@amusewiki.org' });
    foreach my $user (@users) {
        ok !$user->reset_token, "Token cleared for " . $user->username;
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
        ok (!$site->users->reset_password($user->username, $user->reset_token),
            $user->username . " was not reset");
    }

    @users = $site->users->set_reset_token('pallino@amusewiki.org');
    foreach my $user (@users) {
        ok $user->reset_token, "Token generated for " . $user->username;
        ok $user->reset_until, "Timestamp generated for " . $user->username;
    }

    my $check = '';
    foreach my $user (@users) {
        my $new_password = $site->users->reset_password($user->username,
                                                        $user->reset_token);
        ok ($new_password) and diag "New password is $new_password";
        isnt ($new_password, $check);
        $check = $new_password;
    }

    @users = $site->users->search({ email => 'pallino@amusewiki.org' });
    foreach my $user (@users) {
        ok !$user->reset_token, "Token cleared for " . $user->username;
        ok !$user->reset_until, "Timestamp cleared for " . $user->username;
    }
}

is ($site->users->count, 4, "Four users found");

