#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use AmuseWikiFarm::Schema;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my @users = $schema->resultset('User')->all;

foreach my $user (@users) {
    my %data = $user->get_columns;
    print Dumper(\%data);
    $user->password($data{password});
    $user->make_column_dirty('password');
    $user->update;
}
