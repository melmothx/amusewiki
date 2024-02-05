#!perl
use utf8;
use strict;
use warnings;
use Benchmark qw/timethis/;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Test::More tests => 64;
use AmuseWikiFarm::Archive::OAI::PMH;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use URI;


my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0nodes1');

$site->update({ multilanguage => 'en it' });

foreach my $id (qw/one-1 one-2 four-1 four-2 seven/) {
    my ($rev) = $site->create_new_text({
                                        title => "Title " . ucfirst($id),
                                        uri => $id,
                                        lang => 'en',
                                        textbody => '<p>hello there</p>',
                                        author => "Author $id",
                                        cat => "cat-$id",
                                       }, 'text');
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->count;

{
    my $parent;
    foreach my $u (qw/one two three four five six seven eight/) {
        for my $id (0..1) {
            my $uri = "$u-$id";
            my $node = $site->nodes->create({ uri => $uri });
            my %params = (
                          title_en => ucfirst($uri) . ' (en)',
                          body_en => ucfirst($uri) . ' body EN',
                          title_it => ucfirst($uri) . ' (it)',
                          body_it => ucfirst($uri) . ' body IT',
                          parent_node_uri => $parent ? $parent->uri : undef,
                         );
            # test both styles.
            if ($id) {
                my @texts = $site->titles->search({ uri => { -like => '%' . $u . '%' } })->all;
                $params{attached_uris} = [ map { $_->full_uri } @texts ];
            }
            else {
                my @cats = $site->categories->search({ uri => { -like => '%' . $u . '%' } })->all;
                $params{attached_uris} = join(' ', map { $_->full_uri } @cats);
            }
            $node->update_from_params(\%params);
            if ($id) {
                $parent = $node;
            }
        }
    }
}

ok $site->nodes->search_related('node_titles')->count;

my %expect = (
              en => [
                     'One-0 (en)',
                     'One-1 (en)',
                     'One-1 (en) / Two-0 (en)',
                     'One-1 (en) / Two-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en) / Eight-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en) / Eight-1 (en)',
                    ],
              it => [
                     'One-0 (it)',
                     'One-1 (it)',
                     'One-1 (it) / Two-0 (it)',
                     'One-1 (it) / Two-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it) / Eight-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it) / Eight-1 (it)',
                    ],
              
             );

foreach my $lang (qw/en it/) {
    my $list = $site->nodes->as_list_with_path($lang);
    my @out;
    foreach my $i (@$list) {
        push @out, $i->{title};
    }
    is_deeply(\@out, $expect{$lang});
}

foreach my $node ($site->nodes) {
    # title_ids are the title linked via category or directly attached.
    foreach my $title_id (@{ $node->title_ids }) {
        my $title = $site->titles->find($title_id);
        ok $title and diag $node->uri . " has " . $title->uri;
    }
}

# now we need the tree for each title
diag Dumper($site->node_title_tree);

my $oai_pmh = AmuseWikiFarm::Archive::OAI::PMH->new(site => $site,
                                                    oai_pmh_url => URI->new($site->canonical_url . '/oai-pmh'));
$oai_pmh->update_site_records;
{
    my $list_sets = $oai_pmh->process_request({ verb => 'ListSets' });
    diag $list_sets;
    like $list_sets, qr{<setSpec>collection:seven-0</setSpec>};
    like $list_sets, qr{<setSpec>category:topic:cat-one-2</setSpec>};
}

{
    my $test_set = $oai_pmh->process_request({ verb => 'ListRecords',
                                 metadataPrefix => 'oai_dc',
                                 set => "collection:seven-0"
                               });
    like $test_set, qr{
                          \Q<identifier>oai:0nodes1.amusewiki.org:/library/seven</identifier>\E
                          .*
                          \Q<setSpec>collection:one-1</setSpec>\E
                          .*
                          \Q<setSpec>collection:seven-1</setSpec>\E
                  }xs;
    diag $test_set;
}

$oai_pmh->update_site_records({ refresh => 1 });

foreach my $set ("category:author:author-one-1",
                 "category:topic:cat-one-2") {
    my $test_set = $oai_pmh->process_request({ verb => 'ListRecords',
                                               metadataPrefix => 'oai_dc',
                                               set => $set,
                                             });
    like $test_set, qr{<setSpec>web</setSpec>};
    like $test_set, qr{\Q<setSpec>$set</setSpec>\E};
    like $test_set, qr{<dc:title>.*</dc:title>};
    diag $test_set;
}

{
    # first, check if we didn't screw up the by_id method.
    my @all = map { $_->id } $site->titles->all;
    is $site->titles->by_id($all[0])->count, 1;
    is $site->titles->by_id(\@all)->count, scalar(@all);

    sleep 1;
    my $uri = URI->new($site->canonical_url);
    my $now = DateTime->now(time_zone => 'UTC');
    $uri->path('/oai-pmh');
    $uri->query_form({ from => $now->iso8601 . 'Z', metadataPrefix => 'oai_dc', verb => 'ListRecords' });
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

    $mech->get_ok($uri);
    $mech->content_contains('noRecordsMatch');
    sleep 1;
    my $node = $site->nodes->first;
    ok scalar(@{$node->title_ids});
    $node->update_from_params({});
    $mech->get_ok($uri);
    diag $mech->content;
    $mech->content_lacks('noRecordsMatch');

    sleep 1;
    $now = DateTime->now(time_zone => 'UTC');

    $uri->query_form({ from => $now->iso8601 . 'Z',
                       metadataPrefix => 'oai_dc', verb => 'ListIdentifiers' });
    $mech->get_ok($uri);
    $mech->content_contains('noRecordsMatch');

    # create one
    my $root_node = $site->nodes->create({ uri => 'root-oai-pmh' });
    my $child_node = $site->nodes->create({
                                           uri => 'child-oai-pmh',
                                           parent_node => $root_node,
                                          });
    $root_node->update_from_params({
                                    attached_uris => "/library/four-2",
                                   });

    $child_node->update_from_params({
                                     attached_uris => "/library/seven /category/topic/cat-one-1",
                                    });
    sleep 1;
    $mech->get_ok($uri);
    $mech->content_lacks('noRecordsMatch');
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-1', "one-1 is there because of category");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/seven', "seven is there because of direct child");

    # now, ask for the root
    $uri->query_form({ from => $now->iso8601 . 'Z',
                       metadataPrefix => 'oai_dc', verb => 'ListIdentifiers',
                       set => 'collection:root-oai-pmh',
                     });
    $mech->get_ok($uri);
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-1', "one-1 is there because of category");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/seven', "seven is there because of direct child");
    diag $mech->content;
    # diag Dumper($site->node_title_tree);
    sleep 1;
    $now = DateTime->now(time_zone => 'UTC');
    $uri->query_form({ from => $now->iso8601 . 'Z',
                       metadataPrefix => 'oai_dc', verb => 'ListIdentifiers' });

    $mech->get_ok($uri);
    $mech->content_contains('noRecordsMatch');

    # now update the child and ask for the parent
    $child_node->update_from_params({ attached_uris => "/library/one-2" });

    $uri->query_form({ from => $now->iso8601 . 'Z',
                       metadataPrefix => 'oai_dc', verb => 'ListIdentifiers' });
    $mech->get_ok($uri);
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-1', "one-1 is there because of category");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/seven', "seven is there because of direct child");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-2', "one-2 is there because of category");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/four-2', "four-2 is attached to the parent");


    foreach my $set ('collection:root-oai-pmh', 'collection:child-oai-pmh') {
        $uri->query_form({ from => $now->iso8601 . 'Z',
                           metadataPrefix => 'oai_dc', verb => 'ListIdentifiers',
                           set => $set,
                         });
        $mech->get_ok($uri);
        $mech->content_lacks('oai:0nodes1.amusewiki.org:/library/one-1', "one-1 is there because of category");
        $mech->content_lacks('oai:0nodes1.amusewiki.org:/library/seven', "seven is there because of direct child");
        $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-2', "one-2 is there because of category");
        diag $mech->content;
    }
    sleep 1;
    diag "Trying a deletion now";
    $now = DateTime->now(time_zone => 'UTC');
    $uri->query_form({ from => $now->iso8601 . 'Z',
                       metadataPrefix => 'oai_dc', verb => 'ListIdentifiers' });
    $mech->get_ok($uri);
    $mech->content_contains('noRecordsMatch');

    $child_node->delete;
    $mech->get_ok($uri);
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/one-2', "one-2 is there because of category");
    $mech->content_contains('oai:0nodes1.amusewiki.org:/library/four-2', "four-2 is attached to the parent");
    diag $mech->content;
}
