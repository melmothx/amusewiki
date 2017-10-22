#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 61;
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

$site->update({
               ssl_key => '',
               ssl_cert => '',
               ssl_ca_cert => '',
               ssl_chained_cert => '',
               logo => '',
               papersize => 'a4',
               opening => 'right',
              });
$site->discard_changes;


my %old = map { $_ => ($site->$_ || '') } qw/magic_answer
                                             magic_question
                                             fixed_category_list
                                             multilanguage
                                             opening
                                             sitename
                                             siteslogan
                                             logo
                                             mail_notify
                                             mail_from
                                             sitegroup
                                             ttdir
                                             canonical
                                             division
                                             fontsize
                                             bb_page_limit
                                             papersize
                                             mode
                                             locale
                                             mainfont
                                             sansfont
                                             monofont
                                             beamertheme
                                             beamercolortheme
                                             bcor
                                             ssl_key
                                             ssl_cert
                                             ssl_ca_cert
                                             ssl_chained_cert
                                             theme
                                            /;


my @restricted = (qw/active
                     logo
                     logo_with_sitename
                     canonical
                     sitegroup
                     tex
                     html
                     bare_html
                     epub
                     zip
                     ttdir
                     use_luatex
                     vhosts
                     html_special_page_bottom
                     secure_site
                     secure_site_only
                     acme_certificate
                     ssl_key
                     ssl_chained_cert
                     ssl_cert
                     ssl_ca_cert/);

my $original = $site->serialize_site;
foreach my $rest (@restricted) {
    my $error = $site->update_from_params_restricted({ %old, $rest => 1 });
    ok(!$error) or diag $error;
    is_deeply $site->serialize_site, $original, "No changes";
}
diag Dumper(\%old);

foreach my $rest (@restricted) {
    delete $old{$rest};
}

foreach my $good (qw/blog_style twoside nocoverpage cgit_integration/) {
    $site->update({ $good => 0 });
    my $error = $site->update_from_params_restricted({ %old, $good => 1 });
    ok !$error or diag $error;
    is $site->$good, 1, "$good is 1";
}
