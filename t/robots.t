use strict;
use warnings;
use Test::More tests => 62;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };


use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
$site->locale('en');
$site->update;

my @norobots = (
                '/bookbuilder/add',
                '/bookbuilder',
                'bookbuilder/clear',
                'bookbuilder/edit',
                '/console/git',
                '/console/git/action',
                '/action/text/edit/11/11',
                '/action/text/new',
                '/publish/pending',
                '/publish/publish',
                '/tasks/status/1',
                '/admin/pending',
                '/logout',
                '/search',
                '/blabla',
               );
my @yesrobots = (
                 '/authors',
                 '/authors/ciao',
                 '/library',
                 '/library/first-test',
                 '/random',
                 '/help/opds',
                 '/help/irc',
                 '/help/faq',
                 '/topics',
                 '/topics/ecole',
                 '/special',
                 '/special/index',
                );
my $meta = '<meta name="robots" content="noindex,nofollow" />';

$mech->get_ok('/tasks/status/1/ajax');
is $mech->uri->path, '/human';

foreach my $link ('/login', '/human', @norobots) {
    $mech->get($link);
    $mech->content_contains($meta, "$link has noindex, nofollow");
}
$mech->get('/human');

ok($mech->submit_form(with_fields => {username => 'root', password => 'root' },
                      button => 'submit'));

$mech->content_contains('logged in now') or diag $mech->content;
foreach my $link (@norobots) {
    $mech->get($link);
    if ($link eq '/console/git' or $link eq '/console/git/action') {
        is($mech->uri->path, '/special/index', "No git, redirected to /");
    }
    else {
        $mech->content_contains($meta, "$link has noindex, nofollow");
    }
}


foreach my $link (@yesrobots) {
    $mech->get_ok($link);
    $mech->content_lacks($meta, "$link can be indexed");
}


$site->locale('hr');
$site->update;
$mech->get_ok('/robots.txt');
$mech->content_contains('/git');
