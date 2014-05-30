#!perl

use strict;
use warnings;
use Test::More;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

my $site_id = '0user1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);


foreach my $u (qw/pippo pluto pippo pluto/) {
    foreach my $r (qw/librarian root librarian root/) {
        my $got = $site->update_or_create_user({ username => $u,
                                                 password => "xxx$r" }, $r);
        ok ($got->username, "returned  $u $r object");
    }
}

my @users = $site->users;

ok(@users == 2, "Found the two users");

foreach my $u (@users) {
    ok $u->roles->count, "Found roles";
    my %roles = map { $_->role => 1 } $u->roles;
    foreach my $r (qw/librarian root/) {
        ok $roles{$r}, "Found role $r for " . $u->username;
    }
}

done_testing;
