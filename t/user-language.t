#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 48;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0lang0');
my $other = create_site($schema, '0lang1');
my ($username, $password) = (qw/languz mypass/);
$schema->resultset('User')->search({ username => $username })->delete;

my $user = $schema->resultset('User')->create({ username => $username, password => $password,
                                                preferred_language => undef,
                                                user_roles => [ { role => { role => 'librarian' } } ] });

$site->add_to_users($user);
$other->add_to_users($user);

# change lang in the session:

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    log_into_site($mech);
    $mech->content_contains('Create a new special page');
    $mech->get_ok('/publish/pending?__language=hr');
    $mech->content_contains('Stvori novu posebnu stranicu');
    $mech->get_ok('/');
    $mech->content_contains('Stvori novu posebnu stranicu', "Language change is persistent");
}

# new session, same user, language is reset
foreach my $test ($site, $other) {
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $test->canonical);
    log_into_site($mech);
    $mech->get_ok('/publish/pending');
    $mech->content_contains('Create a new special page');
    $mech->content_lacks('Stvori novu posebnu stranicu');
}

# update user preference
{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    log_into_site($mech);
    $mech->get_ok('/user/edit/' . $user->id);
    $mech->submit_form(with_fields => { preferred_language => 'hr' },
                       button => 'update');
}

# now croatian localization popping up upon login
foreach my $test ($site, $other) {
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $test->canonical);
    $mech->get_ok('/');
    $mech->content_contains('Latest entries');
    log_into_site($mech);
    $mech->content_lacks('Latest entries');
    $mech->get_ok('/publish/pending');
    $mech->content_lacks('Create a new special page');
    $mech->content_contains('Stvori novu posebnu stranicu', "Localization OK");
}

# reset preferences
$user->update({ preferred_language => '' });
$site->update({ locale => 'it' });

# site wins.
{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    log_into_site($mech);
    $mech->get_ok('/');
    $mech->content_lacks('Create a new special page');
    $mech->content_contains('Crea una nuova pagina speciale', "Localization OK");
}

sub log_into_site {
    my $mech = shift;
    $mech->get_ok('/'); # warm up
    $mech->get('/publish/pending');
    is ($mech->status, 401, "Bounced to login");
    $mech->get_ok('/login');
    $mech->submit_form(with_fields => { __auth_user => $username,
                                        __auth_pass => $password,
                                      });
}
