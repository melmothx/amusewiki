#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 89;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Path qw/make_path remove_tree/;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

# create a root user

my ($username, $password) = (myroot => "myroot");

my %passwords = ($username => $password);

my $user = $schema->resultset('User')->update_or_create({
                                                         username => $username,
                                                         password => $password,
                                                        });
$user->set_roles({ role => 'root' });


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
    $site_ob->canonical($sites->{$m}->{url});
    my $repo_root = $site_ob->repo_root;
    $site_ob->magic_question('First month of the year');
    $site_ob->magic_answer('January');
    $site_ob->mode($m);
    $site_ob->secure_site(0);
    $site_ob->update;
    ok ((-d $repo_root), "site $sites->{$m}->{url} created");
}

$passwords{pippuzzo} = 'xxxx';
my $outer_user = $schema->resultset('Site')->find('0test0')
  ->update_or_create_user({ username => 'pippuzzo', password => 'xxxx' },
                          'librarian');


diag "Testing the closed site";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $sites->{blog}->{url});

common_tests($mech);
closed_new($mech);
closed_publish($mech);

check_after_login($mech, 0, $user);
check_after_login($mech, 1, $user);

failing_login($mech, $outer_user);

diag "checking the moderated site";

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => $sites->{modwiki}->{url});

common_tests($mech);
diag "common tests done";
open_new($mech);
is $mech->uri->path, '/latest', "After submitting to new + revision, I'm at homepage";
closed_publish($mech);

diag "checking the open site";

check_after_login($mech, 0, $user);
check_after_login($mech, 1, $user);
failing_login($mech, $outer_user);

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => $sites->{openwiki}->{url});

common_tests($mech);
open_new($mech);

is $mech->uri->path, '/publish/pending', "After submitting, I'm on pending!";


check_after_login($mech, 0, $user);
check_after_login($mech, 1, $user);
failing_login($mech, $outer_user);


sub check_after_login {
    my ($mech, $active, $user) = @_;
    $user->active($active);
    $user->update if $user->is_changed;
    $mech->get_ok('/login');

    $mech->form_with_fields('__auth_user');
    $mech->click;

    $mech->form_with_fields('__auth_user');
    $mech->field(__auth_user => 'root');
    $mech->click;

    $mech->form_with_fields('__auth_user');
    $mech->set_fields(__auth_user => '',
                      __auth_pass => 'xxx');
    $mech->click;

    $mech->form_with_fields('__auth_user');
    $mech->set_fields(__auth_user => $user->username,
                      __auth_pass => 'xxx');
    $mech->click;
    $mech->content_contains("Wrong username or password");

    $mech->form_with_fields('__auth_user');
    $mech->set_fields(__auth_user => $user->username,
                      __auth_pass => $passwords{$user->username});
    $mech->click;
    if ($active) {
        diag "user is active";
        $mech->content_contains("You are logged in");
    }
    else {
        diag "user inactive";
        $mech->content_contains("Wrong username or password")
          or diag $mech->content;
    }
    $mech->get_ok('/logout');
}

sub failing_login {
    my ($mech, $user) = @_;
    diag "Checking if " . $user->username . " belonging to another site can login";
    $mech->get_ok('/login');
    $mech->form_with_fields('__auth_user');
    $mech->set_fields(__auth_user => $user->username,
                      __auth_pass => $passwords{$user->username});
    $mech->click;
    $mech->content_contains("Wrong username or password")
      or diag $mech->content;
    is $mech->uri->path, '/login';
}

sub common_tests {
    my $mech = shift;
    $mech->get_ok('/');
    $mech->get('/bookbuilder');
    is $mech->status, 401;
    $mech->content_contains("test if the user is a human");
    $mech->submit_form(
                       with_fields => {
                                       __auth_human => 'January',
                                      },
                      );
    diag "Check if the bookbuilder works";
    is ($mech->uri->path, '/bookbuilder');
    $mech->get('/bookbuilder/add/alsdflasdf');
    is ($mech->status, '404', "Page alsdflasdf not found");
    $mech->content_contains("Couldn't add the text");
    $mech->get('/action/special/new');
    is $mech->status, 401;
    $mech->content_contains('__auth_pass');
}

sub closed_new {
    my $mech = shift;
    $mech->get('/');
    $mech->content_lacks('/action/text/new"');
    diag "Checking /action/text/new";
    $mech->get('/action/text/new');
    is $mech->status, 401;
    $mech->content_contains('__auth_pass');
}

sub closed_publish {
    my $mech = shift;
    diag "Checking pending";
    $mech->get('/publish/pending');
    is $mech->status, 401, "Trying to get publish bounces to login too";
    $mech->content_contains('__auth_pass');
}

sub open_new {
    my $mech = shift;
    $mech->get_ok('/');
    $mech->content_contains('/action/text/new') or diag $mech->response->decoded_content;
    $mech->follow_link_ok( { text_regex => qr/Add a new text/}, "Going on new");
    is $mech->uri->path, '/action/text/new';
    $mech->submit_form(
                       form_id => 'ckform',
                       fields => {
                                  author => 'pinco',
                                  title => 'pallino',
                                  textbody => '<p>This is just a test</p>',
                                 },
                       button => 'go',
                      );
    ok ($mech->success, "post to /action/text/new ok");
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
