#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';    
};

use Test::More tests => 18;
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
$mech->get_ok('/library');
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
    diag Dumper(\@mails);
    like $mails[0]{email}->as_string, qr/sloppy1234/;
}

$mech->get_ok('/logout');
$mech->get_ok('/login');
$mech->content_contains('/reset-password');

# even if the mail doesn't exist, we print out the very same message
foreach my $try ('sloppy@amusewiki.org', 'sloppyxxxxx@amusewiki.org') {
    $mech->get_ok('/reset-password');
    $mech->content_contains('placeholder="example@domain.tld"');
    $mech->submit_form(with_fields => { email => $try });
    $mech->content_contains("alert-success reset-request-sent");
    is $mech->uri->path, "/reset-password", "Path is /reset-password";
    $mech->content_lacks('placeholder="example@domain.tld"');
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
    ok (!@repeat, "no users got repeating the request");
    foreach my $user (@users) {
        my $new_password = $site->users->reset_password($user->username,
                                                        $user->reset_token);
        ok ($new_password) and diag "New password is $new_password";
    }
    @users = $site->users->search({ email => 'pallino@amusewiki.org' });
    foreach my $user (@users) {
        ok !$user->reset_token, "Token cleared for " . $user->username;
        ok !$user->reset_until, "Timestamp cleared for " . $user->username;
    }
}

is ($site->users->count, 4);

