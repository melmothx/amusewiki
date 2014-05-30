#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Amuse qw/muse_naming_algo/;




binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my ($user, $pass, $site_id) = @ARGV;

show_help() unless ($user && $pass);

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $username = muse_naming_algo($user);
die "name $user is invalid, should be $username\n" unless $username eq $user;

my $exists = $schema->resultset('User')->find({ username => $user });

die "$user already exists\n" if $exists;

my $data = {
            username => $user,
            password => $pass,
           };

if ($site_id) {
    my $site = $schema->resultset('Site')->find($site_id);
    die "Couldn't find site $site_id" unless $site;
    $user = $site->update_or_create_user($data, 'librarian');
}
else {
    $user = $schema->resultset('User')->create($data);
    $user->add_to_roles({ role => 'root' });
}
print "User created!\n";
print Dumper({ $user->get_columns });
print "Roles: " . join(" ", map { $_->role } $user->roles) . "\n";

sub show_help {
    print <<"EOF";
Usage: $0 <user> <pass> [<site_id>]

If site_id is passed, then a librarian account is created, other wise
a root one.

EOF
    exit 2;
}





