#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 5;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

my @existing = $site->latest_entries;

my @rss_existing = $site->latest_entries_for_rss;

is (scalar(@existing), scalar(@rss_existing));

my $total = scalar(@existing);

ok($total, "Found $total entries");

# now alter the setting

my $setting = $total - 1;

$site->site_options->update_or_create({ option_name => 'latest_entries',
                                        option_value => $setting });

@existing = $site->latest_entries;
is scalar(@existing), $setting,
  "Now latest entries drop to $setting";

@rss_existing = $site->latest_entries_for_rss;
is scalar(@rss_existing), $total,
  "RSS listing still $total";

$site->site_options->update_or_create({ option_name => 'latest_entries_for_rss',
                                        option_value => $setting });

is scalar(($site->latest_entries_for_rss)), $setting,
  "RSS listing at $setting";


# and reset
$site->site_options->delete;


