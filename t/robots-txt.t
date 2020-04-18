#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 18;
use URI::Escape;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0rbts0');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/robots.txt');
my $robots_txt = $mech->content;
is $robots_txt, $site->robots_txt;
diag $robots_txt;
while ($robots_txt =~ m/https:\/\/0rbts0.amusewiki.org(\S+)/g) {
    $mech->get_ok($1);
    diag $mech->content;
}

my $user = $schema->resultset('User')->update_or_create({ username => 'myadmin', password => 'maypass' });
$user->set_roles([]);
$user->add_to_roles($schema->resultset('Role')->find({ role => "admin" }));
$site->add_to_users($user);

$mech->get('/user/site');
$mech->submit_form(with_fields => { __auth_user => 'myadmin',
                                    __auth_pass => 'maypass',
                                  });

foreach my $str ("pippo\r\npippo\r\n", "pippo\npippo", "pippo\npippo\r\n") {
    $mech->get('/user/site');
    $mech->content_contains($site->robots_txt);
    $mech->submit_form(with_fields => {
                                       robots_txt_override => $str,
                                      },
                       button => 'edit_site');

    $mech->content_contains($site->robots_txt);

    $mech->get_ok('/robots.txt');
    $mech->content_is("pippo\npippo\n");
}

$mech->get('/user/site');
$mech->submit_form(with_fields => {
                                   robots_txt_override => "\n\n\n",
                                  },
                   button => 'edit_site');

$mech->get_ok('/robots.txt');
$mech->content_is($site->robots_txt);
