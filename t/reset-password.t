#!perl
use strict;
use warnings;


BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{EMAIL_SENDER_TRANSPORT} = 'Test';    
};

use Test::More tests => 8;
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
              });
# root login and creates a user
$mech->get_ok('/login');
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
$mech->content_contains('/user/reset-password');
$mech->get_ok('/user/reset-password');

