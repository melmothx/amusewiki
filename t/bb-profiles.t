#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 16;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

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
    }
}

