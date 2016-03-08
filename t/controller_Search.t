use strict;
use warnings;
use Test::More tests => 17;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Search;

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

{
    $mech->get_ok('/search?query=a');
    $mech->content_like(qr/second-test/, "Found a text");
    $mech->get_ok('/search?query=a&complex_query=1&title=My first test&fmt=json');
    $mech->content_like(qr/first-test/, "Found the text");
    $mech->content_unlike(qr/second-test/, "Other title filtered out");
}

{
    $mech->get_ok('/opensearch.xml');
    is $mech->content_type, "application/xml";
    diag $mech->content;
    $mech->content_contains('<Description>' . $site->sitename . '</Description>');
    $mech->content_contains('<SyndicationRight>open</SyndicationRight>');
    my $orig_ml = $site->multilanguage;
    my $orig_mode = $site->mode;
    $site->update({ mode => 'private', multilanguage => 'hr en de' });
    $mech->content_contains('<Description>' . $site->sitename . '</Description>');
    is_deeply([$site->supported_locales], [qw/de en hr/]);
    $mech->get_ok('/opensearch.xml');
    is ($mech->uri->path, '/login');
    $mech->submit_form(form_id => 'login-form',
                       fields => { username => 'root',
                                   password => 'root',
                                 },
                       button => 'submit');
    diag $mech->content;
    $mech->content_contains('<SyndicationRight>limited</SyndicationRight>');
    foreach my $lang ($site->supported_locales) {
        $mech->content_contains("<Language>$lang</Language>");
    }
    $site->update({ mode => $orig_mode, multilanguage => $orig_ml });
}

