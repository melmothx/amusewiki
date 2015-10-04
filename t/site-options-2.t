#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 11;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0opts0');

my %tests = (
             latest_entries => 10,
             latest_entries_for_rss => 15,
             paginate_archive_after => 23,
             html_special_page_bottom => '<script>alert("hello")</script>',
             use_luatex => 1,
             do_not_enforce_commit_message => 1,
            );

foreach my $opt (keys %tests) {
    $site->site_options->update_or_create({
                                           option_name => $opt,
                                           option_value => $tests{$opt},
                                          });
}

my %settings;
my $options = $site->site_options;
while (my $option = $options->next) {
    $settings{$option->option_name} = $option->option_value;
}
is_deeply \%settings, \%tests, "Thing stored";

foreach my $opt (keys %tests) {
    ok($site->get_option($opt), "Found $opt in settings");
}
is $site->html_special_page_bottom, $tests{html_special_page_bottom};
ok $site->use_luatex, "Use luatex";
ok $site->do_not_enforce_commit_message, "Do not enforce commit message";
ok !$site->get_option('lakjsdfl');

