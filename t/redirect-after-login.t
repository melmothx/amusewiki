#!perl

use strict;
use warnings;

use Test::More tests => 33;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0user3';
my $site = create_site($schema, $site_id);
$site->update({
               mode => 'modwiki',
               magic_question => 'x',
               magic_answer => 'x',
               pdf => 0,
              });


{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");
    $mech->get_ok('/');
    $mech->get_ok('/bookbuilder');
    is ($mech->uri->path, '/human');
    $mech->submit_form(with_fields => {
                                       answer => 'x',
                                      },
                       button => 'submit');
    is ($mech->uri->path, '/bookbuilder');

    # then test the editing

    $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                host => "$site_id.amusewiki.org");


    $mech->get_ok('/action/text/new');
    is ($mech->uri->path, '/human');
    $mech->submit_form(with_fields => {
                                       answer => 'x',
                                      },
                       button => 'submit');
    is ($mech->uri->path, '/action/text/new');

    $mech->get_ok('/action/special/new');
    is ($mech->uri->path, '/login');
    $mech->submit_form(with_fields => {
                                       username => 'root',
                                       password => 'root',
                                      },
                       button => 'submit');
    is ($mech->uri->path, '/action/special/new');
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

    my ($revision) = $site->create_new_text({ uri => 'the-text',
                                              title => 'Hello',
                                              lang => 'hr',
                                              textbody => '',
                                            }, 'text');
    $revision->edit("#title blabla\n#author Pippo\n#topics the cat\n#lang en\n\n** blabla\n\n Hello world!\n\n** blu\n\nciao\n");
    $revision->commit_version;
    my $uri = $revision->publish_text;
    diag $uri;
    $mech->get_ok($uri);
    ok($mech->submit_form(form_id => 'book-builder-add-text-partial'));
    is ($mech->uri->path, '/library/the-text/bbselect');
    $mech->content_contains(q{value="1"});
    ok($mech->form_id("book-builder-add-text-partial"), "Selected form for partials");
    $mech->tick(select => 1);
    $mech->click;
    is ($mech->uri->path, '/human', "Got to /human");
    $mech->content_like(qr{\Qname="goto" value="bookbuilder/add/the-text?\E[^"]*select=1}) or diag $mech->content;
    $mech->content_like(qr{\Qname="goto" value="bookbuilder/add/the-text?\E[^"]*select=pre});
    $mech->content_like(qr{\Qname="goto" value="bookbuilder/add/the-text?\E[^"]*partial=1});
    $mech->submit_form(with_fields => {
                                       answer => 'x',
                                      },
                       button => 'submit');
    is ($mech->uri->path, $uri, "Landed back to $uri");
    $mech->get_ok('/bookbuilder');
    $mech->content_contains('/library/the-text');
    $mech->content_contains('the-text/bbselect?selected=pre-1');
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

    ok($mech->get_ok('/library/the-text/edit'));
    is ($mech->uri->path, '/human', "Got to /human");
    $mech->content_contains(q{name="goto" value="action/text/edit/the-text"}) or diag $mech->content;
    $mech->submit_form(with_fields => {
                                       answer => 'x',
                                      },
                       button => 'submit');
    diag $mech->uri->path_query;
    like ($mech->uri->path_query, qr{\A/action/text/edit/the-text/\d+\z});
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

    ok($mech->get_ok('/category/topic/the-cat/edit'));
    is ($mech->uri->path, '/login', "Got to /login");
    $mech->content_contains(q{name="goto" value="category/topic/the-cat/en/edit"}) or diag $mech->content;
    $mech->submit_form(with_fields => {
                                       username => 'root',
                                       password => 'root',
                                      },
                       button => 'submit');
    diag $mech->uri->path_query;
    is ($mech->uri->path_query, '/category/topic/the-cat/en/edit');
}


