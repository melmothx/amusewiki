#!perl

use strict;
use warnings;

use Test::More tests => 42;
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
    $mech->get('/bookbuilder');
    is $mech->status, 401;
    is ($mech->uri->path, '/bookbuilder');
    $mech->submit_form(with_fields => {
                                       __auth_human => 'x',
                                      });
    is ($mech->uri->path, '/bookbuilder');
    $mech->content_lacks('__auth_human');

    # then test the editing

    $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                host => "$site_id.amusewiki.org");

    $mech->get_ok('/');
    $mech->get('/action/text/new');
    is ($mech->status, 401);
    $mech->submit_form(with_fields => {
                                       __auth_human => 'x',
                                      });
    is ($mech->uri->path, '/action/text/new');
    $mech->content_lacks('__auth_human');

    $mech->get('/action/special/new');
    is ($mech->status, 401);
    $mech->submit_form(with_fields => {
                                       __auth_user => 'root',
                                       __auth_pass => 'root',
                                      });
    is ($mech->uri->path, '/action/special/new');
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get_ok('/');
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
    is $mech->status, 401;
    $mech->content_like(qr{type="hidden" name="select" value="1".*type="hidden" name="select" value="1"}s);
    $mech->submit_form(with_fields => {
                                       __auth_human => 'x',
                                      });
    is ($mech->uri->path, $uri, "Landed back to $uri");
    $mech->get_ok('/bookbuilder');
    $mech->content_contains('/library/the-text');
    $mech->content_contains('the-text/bbselect?selected=pre-1');
}
{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get_ok('/');
    my $uri = '/library/the-text';
    $mech->get_ok("$uri/bbselect");
    ok($mech->form_id("book-builder-add-text-partial"), "Selected form for partials");
    $mech->tick(select => 'pre');
    $mech->click;
    is $mech->status, 401;
    $mech->content_like(qr{type="hidden" name="select" value="pre".*type="hidden" name="select" value="pre"}s);
    $mech->submit_form(with_fields => {
                                       __auth_user => 'root',
                                       __auth_pass => 'root',
                                      });
    is ($mech->uri->path, $uri, "Landed back to $uri");
    $mech->get_ok('/bookbuilder');
    $mech->content_contains('/library/the-text');
    $mech->content_contains('the-text/bbselect?selected=pre') or die $mech->content;
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);

    $mech->get_ok('/');
    $mech->get('/library/the-text/edit');
    is $mech->status, 401;
    $mech->content_contains(q{__auth_human});
    $mech->submit_form(with_fields => {
                                       __auth_human => 'x',
                                      });
    diag $mech->uri->path_query;
    like ($mech->uri->path_query, qr{\A/action/text/edit/the-text/\d+\z});
}

{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => $site->canonical);
    $mech->get_ok('/');
    $mech->get('/category/topic/the-cat/edit');
    is $mech->status, 401;
    $mech->submit_form(with_fields => {
                                       __auth_user => 'root',
                                       __auth_pass => 'root',
                                      });
    diag $mech->uri->path_query;
    is ($mech->uri->path_query, '/category/topic/the-cat/en/edit');
    is $mech->status, 200;
    $mech->content_lacks('__auth');
    $mech->content_contains('/logout');
}


