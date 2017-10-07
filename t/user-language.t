
#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 19;
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
                                                user_roles => [ { role => { role => 'librarian' } } ] });

$site->add_to_users($user);
$other->add_to_users($user);

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get_ok('/'); # warm up
    $mech->get('/publish/pending');
    is ($mech->status, 401, "Bounced to login");
    $mech->get_ok('/login');
    $mech->content_contains('Lost your password?');
    $mech->submit_form(with_fields => { __auth_user => $username,
                                        __auth_pass => $password,
                                      });
    $mech->content_contains('Create a new special page');
    $mech->get_ok('/publish/pending?__language=hr');
    $mech->content_contains('Stvori novu posebnu stranicu');
}

foreach my $test ($site, $other) {
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $test->canonical);
    $mech->get_ok('/'); # warm up
    $mech->get_ok('/login');
    $mech->content_contains('Lost your password?');
    $mech->submit_form(with_fields => { __auth_user => $username,
                                        __auth_pass => $password,
                                      });
    $mech->get_ok('/publish/pending');
    $mech->content_lacks('Create a new special page');
    $mech->content_contains('Stvori novu posebnu stranicu');
}
