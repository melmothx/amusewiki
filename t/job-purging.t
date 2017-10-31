#!perl

use strict;
use warnings;
use Test::More tests => 2;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWikiFarm::Schema;
use DateTime;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

$schema->resultset('Job')->delete;
my %schedule = $schema->resultset('Job')->purge_schedule;
diag Dumper(\%schedule);

my $total = 0;

foreach my $j (keys %schedule) {
    my $days = $schedule{$j};
    my $old = DateTime->now->subtract(days => ($days + 1));
    my $keep = DateTime->now->subtract(days => ($days - 1));
    foreach my $date ($old, $keep) {
        foreach my $status (qw/completed pending taken/) {
            diag "Creating $j $date $status";
            $total++;
            $schema->resultset('Job')->create({
                                               site_id => '0blog0',
                                               task => $j,
                                               status => $status,
                                               created => $date,
                                               completed => $date,
                                              });
        }
    }
}

is $schema->resultset('Job')->count, $total, "Total jobs is $total";
$schema->resultset('Job')->purge_old_jobs;
is $schema->resultset('Job')->count, ($total - $total/2/3), "Total jobs now is ". ($total - $total/2/3);
