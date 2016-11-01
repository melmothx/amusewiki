#!perl
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use strict;
use warnings;
use Test::More tests => 42;
use File::Spec;
use Data::Dumper;
use File::Spec::Functions qw/catfile/;
use Cwd;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');
my $old_locale = $site->locale;
$site->update({locale => 'en'});
my $mech1 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
my $mech2 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                host => $site->canonical);

my $mech3 = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                host => 'test.amusewiki.org');

for my $mech ($mech1, $mech2, $mech3) {
    # we need to hit the root, otherwise session is not picked up. Mah!
    $mech->get_ok('/');
    $mech->get('/bookbuilder');
    is $mech->status, 401;
    $mech->content_contains("test if the user is a human");
    $mech->submit_form(with_fields => {'__auth_human' => 'January' });
    $mech->get_ok('/bookbuilder');
}

$mech1->get_ok('/bookbuilder/add/first-test');
$mech1->get_ok('/bookbuilder');
my $sid1;
if ($mech1->content =~ m{<span class="bb-token-id">(.*)</span>}) {
    $sid1 = $1;
}
ok ($sid1, "Found the sid $sid1") or die;
$mech1->content_contains('/library/first-test');
$mech2->get_ok('/bookbuilder');
$mech2->content_lacks('/library/first-test');
my $coverfile = File::Spec->catfile(qw/t files shot.png/);
$mech1->submit_form(with_fields => {
                                    title => 'My nice title',
                                    mainfont => 'Iwona',
                                    coverimage => $coverfile,
                                   },
                    button => 'update');
# check the cover upload
$mech1->get_ok('/bookbuilder/cover');
$mech2->get('/bookbuilder/cover');
is $mech2->status, '404';
$mech2->get_ok('/bookbuilder');
$mech2->submit_form(with_fields => { token => $sid1 });
# now the cover is found
$mech2->content_contains('My nice title');
$mech2->content_like(qr{Iwona"\s+selected}s);
$mech2->content_contains('/library/first-test');
$mech2->get_ok('/bookbuilder/cover');
$mech1->get_ok('/bookbuilder');
$mech1->submit_form(with_fields => {
                                    removecover => 1,
                                    title => 'Blablabla',
                                  },
                    button => 'update',
                   );

# Check if the sessions are disconnected
$mech1->content_contains('Blablabla');
$mech1->get('/bookbuilder/cover');
is $mech1->status, '404';

$mech2->get_ok('/bookbuilder/cover');
$mech2->get_ok('/bookbuilder');
$mech2->content_contains('My nice title');
$mech2->content_contains('/library/first-test');

# Try to load a non-existent session
my $sid2 = 'X' . $sid1;
$mech2->submit_form(with_fields => { token => $sid2 });
$mech2->content_contains('Unable to load the bookbuilder session');
$mech2->content_contains('My nice title');
$mech2->content_contains('/library/first-test');
$mech2->get_ok('/bookbuilder/cover');

$mech2->get_ok('/bookbuilder');
for my $invalid ('X' . $sid1, $sid1 . 'X', "invalid", 0) {
    $mech2->submit_form(with_fields => { token => $invalid });
    $mech2->content_contains('Unable to load the bookbuilder session',
                             "warning msg with $invalid");
}
$site->update({locale => $old_locale});

$mech3->submit_form(with_fields => { token => $sid1 });
$mech3->content_contains('Unable to load the bookbuilder session',
                         "warning msg when loading the session from another site");

