#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib 'lib';
use AmuseWikiFarm::Schema;


my $schema = AmuseWikiFarm::Schema->connect('amuse');

my ($username, $password) = @ARGV;

die "Usage: $0 <username> <password>\n" unless $username && $password;

if (my $user = $schema->resultset('User')->find({ username => $username })) {
    $user->password($password);
    $user->update;
    print "Password for $username is now $password\n";
}
else {
    die "No such user $username!";
}


