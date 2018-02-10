#!perl

use strict;
use warnings;

use Test::More tests => 70;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0editingopts0');
$schema->resultset('User')->search({ username => 'u' . $site->id })->delete;
my $user = $schema->resultset('User')->create({
                                               username => 'u' . $site->id,
                                               password => 'u' . $site->id,
                                              })->discard_changes;
$site->update({ mode => 'openwiki',
                magic_question => '?',
                magic_answer => '?',
              });
$site->add_to_users($user);
$user->add_to_roles({ role => 'admin' });

my %defaults = (
                edit_option_preview_box_height =>  500,
                edit_option_show_filters =>  1,
                edit_option_show_cheatsheet =>  1,
                edit_option_page_left_bs_columns => 6,
               );
foreach my $method (keys %defaults) {
    is $site->$method, $defaults{$method}, "site.$method is fine";
    is $user->$method, $defaults{$method}, "user.$method is fine;"
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get('/');
$mech->get_ok('/human');
$mech->submit_form(with_fields => { __auth_human => '?' });
is $mech->status, 200;
$mech->get_ok('/action/text/new');
$mech->submit_form(with_fields => { title => 'blablabla' },
                   button => 'go',
                  );
my $test_uri = $mech->uri->path;
diag $test_uri;
check_default($mech);

foreach my $path ('/user/site', '/user/edit/'. $user->id . '/options') {
    $mech->get('/');
    $mech->get($path);
    is $mech->status, 401;
    $mech->submit_form(with_fields => { __auth_user => 'u' . $site->id, __auth_pass => 'u' . $site->id, });
    is $mech->status, 200;
    $mech->form_with_fields(qw/edit_option_preview_box_height
                               edit_option_page_left_bs_columns/);
    $mech->untick(edit_option_show_filters => 1);
    $mech->untick(edit_option_show_cheatsheet => 1);
    $mech->field(edit_option_preview_box_height => 400);
    $mech->field(edit_option_page_left_bs_columns => 3);
    $mech->click;
    my $object = $path eq '/user/site' ? $site : $user;
    diag "testing " . ref($object);
    $object->discard_changes;
    is $object->edit_option_preview_box_height, 400;
    is $object->edit_option_page_left_bs_columns, 3;
    is $object->edit_option_show_filters, 0;
    is $object->edit_option_show_cheatsheet, 0;

    $mech->get_ok($test_uri);
    # changed globally, but we're logged in;
    if ($path eq '/user/site') {
        diag "Changed globally, logged in";
        check_default($mech);
    }
    # changed per user, and we're logged in;
    else {
        diag "Changed per user, logged in";
        check_modified($mech);
    }
    $mech->get_ok('/logout');
    # changed globally, logged out
    $mech->get_ok($test_uri);
    is $mech->uri->path, $test_uri or die;

    if ($path eq '/user/site') {
        diag "changed per globally, logged out";
        check_modified($mech);
    }
    # changed per user, logged out
    else {
        diag "changed per user, logged out";
        check_default($mech);
    }
    $user->update({ %defaults });
    foreach my $k (keys %defaults) {
        $site->site_options->search({ option_name => $k })->update({ option_value => $defaults{$k} });
    }
    $mech->get_ok($test_uri);
    is $mech->uri->path, $test_uri or die;
    diag "Reset, checking logged out";
    check_default($mech);
}
$user->delete;

sub check_default {
    my $mech = shift;
    $mech->content_like(qr{id="page"\s*class="col-sm-6\s*col-sm-push-6}s) or die $mech->content;
    $mech->content_contains(q{style="height: 500px});
    $mech->content_like(qr{id="edit-page-left-panels"\s*class="col-sm-6\s*col-sm-pull-6}s);
    $mech->content_like(qr{data-target="#filters"[^>]*aria-expanded="true"}s);
    $mech->content_like(qr{data-target="#cheatsheet-panel"[^>]*aria-expanded="true"}s);
}

sub check_modified {
    my $mech = shift;
    $mech->content_like(qr{id="page"\s*class="col-sm-9\s*col-sm-push-3}s) or die $mech->content;
    $mech->content_contains(q{style="height: 400px});
    $mech->content_like(qr{id="edit-page-left-panels"\s*class="col-sm-3\s*col-sm-pull-9}s);
    $mech->content_like(qr{data-target="#filters"[^>]*aria-expanded="false"}s);
    $mech->content_like(qr{data-target="#cheatsheet-panel"[^>]*aria-expanded="false"}s);

}
