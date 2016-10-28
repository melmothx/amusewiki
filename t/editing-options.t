#!perl

use strict;
use warnings;

use Test::More tests => 22;
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
    $mech->get_ok('/logout');
}
$user->delete;
