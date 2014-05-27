#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 44;
use File::Path qw/make_path remove_tree/;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $sites = {
             blog  => { id => '0closed0',
                          url  => 'closed.amusewiki.org',
                        },
             modwiki => { id => '0modewiki0',
                          url  => 'modwiki.amusewiki.org',
                        },
             openwiki => { id => '0openwiki0',
                           url  => 'openwiki.amusewiki.org',
                         },
            };
diag "Creating sites";
foreach my $m (keys %$sites) {
    my $site_ob = create_site($schema, $sites->{$m}->{id});
    $site_ob->add_to_vhosts({ name => $sites->{$m}->{url} });
    my $repo_root = $site_ob->repo_root;
    $site_ob->magic_question('First month of the year');
    $site_ob->magic_answer('January');
    $site_ob->mode($m);
    $site_ob->update;
    ok ((-d $repo_root), "site $sites->{$m}->{url} created");
}

diag "Testing the closed site";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $sites->{blog}->{url});

common_tests($mech);
closed_new($mech);
closed_publish($mech);

diag "checking the moderated site";

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => $sites->{modwiki}->{url});

common_tests($mech);
open_new($mech);
is $mech->uri->path, '/login', "After submitting to new + revision, I'm at login";
closed_publish($mech);

diag "checking the open site";

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => $sites->{openwiki}->{url});

common_tests($mech);
open_new($mech);

is $mech->uri->path, '/publish/pending', "After submitting, I'm on pending!";

sub common_tests {
    my $mech = shift;
    $mech->get_ok('/');
    $mech->get_ok('/bookbuilder/');
    $mech->content_contains("test if the user is a human");
    $mech->submit_form(
                       form_name => 'human',
                       fields => {
                                  answer => 'January',
                                 },
                      );
    diag "Check if the bookbuilder works";
    $mech->get_ok('/bookbuilder/add?text=alsdflasdf');
    $mech->content_contains("Couldn't add the text");
}

sub closed_new {
    my $mech = shift;
    $mech->get('/');
    $mech->content_lacks('/new/text"');
    diag "Checking /new";
    $mech->get('/new/text');
    is $mech->uri->path, '/login', "Bounced to login";
}

sub closed_publish {
    my $mech = shift;
    diag "Checking pending";
    $mech->get('/publish/pending');
    is $mech->uri->path, '/login', "Trying to get publish bounces to login too";
}

sub open_new {
    my $mech = shift;
    $mech->get_ok('/');
    $mech->content_contains('/new/text') or diag $mech->response->decoded_content;
    $mech->follow_link_ok( { text_regex => qr/Add to library/}, "Going on new");
    is $mech->uri->path, '/new/text';
    $mech->submit_form(
                       form_id => 'ckform',
                       fields => {
                                  author => 'pinco',
                                  title => 'pallino',
                                  textbody => '<p>This is just a test</p>',
                                 },
                       button => 'go',
                      );
    ok ($mech->success, "post to /new ok");
    if ($mech->uri->path =~ m{pinco-pallino/(\d+)$}) {
        my $rev = $schema->resultset('Revision')->find($1);
        ok ($rev, "Got a revision $1");
        my $muse = $rev->muse_body;
        like $muse, qr/#title pallino/, "Found the title";
        like $muse, qr/#lang en/, "Found the language";
        like $muse, qr/This is just a test/, "Found the body";
    }
    else {
        for (1..4) {
            ok (0, "Couldn't create a revision");
        }
    }
    $mech->submit_form(form_id => 'museform',
                       button => 'commit');
    $mech->content_contains("Changes committed, thanks!");
}
