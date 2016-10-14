#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 30;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use DateTime;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0profusers0');

foreach my $name (qw/profiler1 profiler2/) {
    $schema->resultset('User')->search({ username => $name })->delete;

    my $user = $site->update_or_create_user({
                                             username => $name,
                                             password => $name,
                                            });

    is $user->username, $name, "Username ok";
    is $user->roles->first->role, 'librarian', "Role ok";
    is $user->bookbuilder_profiles->count, 0, 'No profiles found for user';
    ok !$user->bookbuilder_profiles->find(1), "No profile found with id 1";
    {
        my $bb_title = $name . ' àć';
        my $bb = AmuseWikiFarm::Archive::BookBuilder->new(title => $name . ' àć');
        my $profile = $user->add_bb_profile(test => $bb);
        my $pid = $profile->bookbuilder_profile_id;
        ok $pid;
        my $found = $user->bookbuilder_profiles->find($pid);
        is $found->profile_name, "test", "Found the profile";
        is $user->bookbuilder_profiles->count, 1, "Found 1 profile";
        my $data = $user->bookbuilder_profiles->find($pid)->bookbuilder_arguments;
        is $data->{title}, $bb_title;
        $found->update({ profile_data => 'alsdkfjlaskdjf'});
        is_deeply $found->bookbuilder_arguments, {}, "No args on random data";
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

# add a dummy text

$site->add_to_titles({
                      title => "my-dummy-title",
                      f_class => "text",
                      uri => "my-dummy-text",
                      pubdate => DateTime->now,
                      status => "published",
                      f_path => "dummy",
                      f_name => "dummy.muse",
                      f_archive_rel_path => "",
                      f_timestamp => 1234,
                      f_full_path_name => '',
                      f_suffix => ".muse",
                      sorting_pos => 1,
                     });

$mech->get('/bookbuilder/add/my-dummy-text');
is $mech->status, 403;
$mech->submit_form(form_id => 'login-form',
                   fields => { __auth_user => 'profiler1',
                               __auth_pass => 'profiler1',
                             });
diag $mech->uri;
diag Dumper($mech->response->headers);
$mech->get_ok('/bookbuilder');
$mech->content_contains("/library/my-dummy-text");
$mech->content_like(qr{/bookbuilder/profile/\d+\"});
$mech->submit_form(with_fields => {
                                   title => 'this is the bookbuilder title',
                                  },
                   button => 'update');

$mech->submit_form(form_id => 'bb-create-profile-form',
                   fields => { profile_name => 'profile with title' },
                   button => 'create_profile',
                  );

# peek into the db. Here we can't possibly test everything, but in
# case we have the routine ready.
{
    $mech->submit_form(with_fields => {
                                       title => 'xxxxxxxxx',
                                      },
                       button => 'update');
    $mech->content_contains("xxxxxxxxx");
    $mech->content_lacks("this is the bookbuilder title");
    my $user = $schema->resultset('User')->find({ username => 'profiler1' });
    ok ($user);
    my $profile = $user->bookbuilder_profiles->search({
                                                       profile_name => 'profile with title'
                                                      })->first;
    ok $profile;
    diag $profile->bookbuilder_profile_id;
    like $profile->profile_data, qr{this is the bookbuilder title};
    # and load it
    $mech->submit_form(form_id => 'bb-profile-operation-' . $profile->bookbuilder_profile_id,
                       button => 'profile_load');
    $mech->content_contains('this is the bookbuilder title');
    $mech->content_lacks("xxxxxxxxx", "title reset with load");
    $mech->get('/bookbuilder/profile/' . ($profile->bookbuilder_profile_id + 100));
    is $mech->status, '404';
}

