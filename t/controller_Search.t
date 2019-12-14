use strict;
use warnings;
use Test::More tests => 35;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Catalyst::Test 'AmuseWikiFarm';
use AmuseWikiFarm::Controller::Search;

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Search::Xapian (':all');
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

$site->xapian->delete_text_by_uri('this-uri-doesnt-exist');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
{
    $mech->get_ok('/search?query=');
}

{
    $mech->get('/search?query=asdfasdfasdf+OR+OR+OR');
    is $mech->status, 404;
    $mech->content_contains('Exception');
}

{
    $mech->get_ok('/search?query=a');
    $mech->content_like(qr/second-test/, "Found a text") or die $mech->content;
    $mech->get_ok('/search?query=title:"My first test"&fmt=json');
    diag $mech->content;
    $mech->content_like(qr/first-test/, "Found the text");
    $mech->content_unlike(qr/second-test/, "Other title filtered out");
    is $mech->content_type, "application/json";
    $mech->get_ok('/search?query=a*&fmt=json');
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
    $mech->content_contains('<SyndicationRight>limited</SyndicationRight>');
    foreach my $lang ($site->supported_locales) {
        $mech->content_contains("<Language>$lang</Language>");
    }
    $site->update({ mode => $orig_mode, multilanguage => $orig_ml });
}
{
    # ensure that we don't die when we have an out of sync db, with
    # stuff which wasn't supposed to be there
    my $uri = 'this-uri-doesnt-exist';
    {
        my $xapian = $schema->resultset('Site')->find('0blog0')->xapian;
        ok $xapian->xapian_stemmer('asdfasdf'), "Unknown language return a none stemmer";
        my $db = $xapian->xapian_db;
        my $indexer = Search::Xapian::TermGenerator->new();
        my $doc = Search::Xapian::Document->new();
        $indexer->set_stemmer($xapian->xapian_stemmer);
        $indexer->set_document($doc);
        $doc->set_data(qq[{ "uri":"$uri" }]);
        $doc->add_term('Q' . $uri);
        # SLOT_PUBDATE_FULL, otherwise search will fail because of the default filter.
        $doc->add_value(7, Search::Xapian::sortable_serialise(time() - 1));
        $indexer->index_text($uri, 1, 'S');
        $indexer->increase_termpos();
        $indexer->index_text("this uri doesn't exist a abc cdf");
        $db->replace_document_by_term('Q' . $uri, $doc);
    }
    {
        my $xapian = $schema->resultset('Site')->find('0blog0')->xapian;
        my ($pager, @res) = $xapian->search("uri:$uri");
        is ($res[0]{pagedata}{uri}, $uri, "Found the uri");
    }
    for (1..2) {
        $mech->get_ok("/search?query=uri:first-test&fmt=json");
        $mech->content_contains('first-test');
        diag $mech->content;
        $mech->get_ok("/search?query=uri:$uri&fmt=json");
        $mech->content_contains(qq{"uri":"$uri"}, "$uri is still present, no exception");
        $mech->get_ok("/search?query=uri:$uri");
        $mech->content_lacks(q{id="results"}) or diag $mech->content;
    }
}
