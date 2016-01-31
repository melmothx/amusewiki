#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 19;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use File::Copy qw(move copy);

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

@rss_existing = $site->latest_entries_for_rss;
is scalar(@rss_existing), $setting,
  "RSS listing at $setting";


is ($site->get_option('latest_entries_for_rss'), $setting);


# and reset
$site->site_options->delete;

$site = create_site($schema, '0pening0');

my $old_opening = $site->opening;

$site->update({ opening => 'any' });

my %old = map { $_ => ($site->$_ || '') } qw/magic_answer
                                  magic_question
                                  fixed_category_list
                                  multilanguage
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
                                 /;

my $errors = $site->update_from_params({
                                        %old,
                                        papersize => 'a4',
                                        bcor => '0mm',
                                        opening => 'right',
                                        sansfont => 'Iwona',
                                        beamercolortheme => 'wolverine',
                                        beamertheme => 'Madrid',
                                       });
ok(!$errors, "No errors found") or diag $errors;
is $site->opening, 'right', "Site updated";

$errors = $site->update_from_params({
                                     %old,
                                     bcor => '0mm',
                                     papersize => 'a4',
                                     opening => 'lasdf',
                                    });
like $errors, qr/invalid opening/i, "Errors found: $errors";
is $site->opening, 'right', "Site not updated";

$site->update({ opening => $old_opening });

$old{papersize} = 'a4';
$old{opening} = 'any';

my $html_injection = q{<script>alert('hullo')</script>};

$errors = $site->update_from_params({ %old,
                                      html_special_page_bottom => $html_injection,
                                    });
ok(!$errors, "No errors") or diag Dumper($errors);

is $site->html_special_page_bottom, $html_injection, "html stored";

# reset
$errors = $site->update_from_params({ %old });

ok(!$errors, "No errors");

is $site->html_special_page_bottom, '', "html wiped out";

my @links = ({
              url => 'http://bau.org',
              label => 'Bauuuu',
              sorting_pos => 0,
             },
             {
              url => 'http://bau2.org',
              label => 'Bauuuu 2',
              sorting_pos => 1,
             });

$site->site_links->delete;
foreach my $link (@links) {
    $site->site_links->create($link);
}

my @outlinks = $site->deserialize_links($site->serialize_links);
is_deeply(\@outlinks, \@links, "de/serialize works");
diag $site->serialize_links;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

$mech->get_ok('/', "Crash 1.22 fixed");

{
    $site = $schema->resultset('Site')->find('0blog0');
    $site->site_options->update_or_create({ option_name => 'use_js_highlight',
                                            option_value => 'perl' });
    is $site->get_option('use_js_highlight'), 'perl';
    is $site->use_js_highlight_value, 'perl';
    is $site->use_js_highlight, '{"languages":["perl"]}';

}
