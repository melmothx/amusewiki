#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 52;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use File::Copy qw(move copy);
use HTML::Entities;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = $schema->resultset('Site')->find('0blog0');

my @rss_existing = $site->latest_entries_for_rss_rs;
diag "RSS entries: " . scalar(@rss_existing);

my $setting = scalar(@rss_existing) - 1;

$site->site_options->update_or_create({ option_name => 'latest_entries_for_rss',
                                        option_value => $setting });

# refetch the site
$site = $schema->resultset('Site')->find('0blog0');

@rss_existing = $site->latest_entries_for_rss_rs;
is scalar(@rss_existing), $setting,
  "RSS listing at $setting";


is ($site->get_option('latest_entries_for_rss'), $setting);
is ($site->latest_entries_for_rss, $setting);


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
                                  theme
                                  binary_upload_max_size_in_mega
                                 /;

my $errors = $site->update_from_params({
                                        %old,
                                        papersize => 'a4',
                                        bcor => '0mm',
                                        opening => 'right',
                                        sansfont => 'TeX Gyre Heros',
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

$errors = $site->update_from_params({
                                     %old,
                                     site_links => "pincopallino\n",
                                    });

ok $errors, "Validate the links";

# reset
$errors = $site->update_from_params({ %old });

ok(!$errors, "No errors");

is $site->html_special_page_bottom, '', "html wiped out";

my @links = ({
              url => 'http://bau.org',
              label => 'Bauuuu',
              sorting_pos => 0,
              menu => 'specials',
             },
             {
              url => 'http://bau2.org',
              label => 'Bauuuu 2',
              sorting_pos => 1,
              menu => 'specials',
             });

$site->site_links->delete;
foreach my $link (@links) {
    $site->site_links->create($link);
}

foreach my $type ('specials') {
    my @outlinks = @{ $site->deserialize_links($site->serialize_links($type), $type)->{links} };
    is_deeply(\@outlinks, \@links, "de/serialize works");
    diag $site->serialize_links($type);
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

$mech->get_ok('/', "Crash 1.22 fixed");

{
    $site = $schema->resultset('Site')->find('0blog0');
    $site->site_options->update_or_create({ option_name => 'use_js_highlight',
                                            option_value => 'perl tex' });
    is $site->get_option('use_js_highlight'), 'perl tex';
    is $site->use_js_highlight_value, 'perl tex';
    like $site->use_js_highlight, qr{\A
                                     \s*\{
                                     \s*"languages"\s*:
                                     \s*\[\s*"perl",\s*
                                     "tex"
                                     \s*\]
                                     \s*\}
                                     \s*\z}sx;
}

$mech->get_ok('/login');
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get_ok('/user/site');

$mech->submit_form(with_fields => {
                                   site_links => "https://prova.org TEST1\nhttps://prova.org <TEST2>\n",
                                   site_links_projects => "/library/prova-prova TEST1\nhttps://prova.org <TEST2>\n",
                                   site_links_archive => "https://prova.org TEST1\n/prova/prova <TEST2>\n",
                                  },
                   button => 'edit_site');

is $site->site_links->count, 6;
$mech->get_ok('/');
foreach my $link ($site->site_links->all) {
    $mech->content_contains(encode_entities($link->url));
    $mech->content_contains(encode_entities($link->label));
}

$mech->get_ok('/user/site');
$mech->submit_form(with_fields => {
                                   site_links => "\n",
                                   site_links_projects => "\n",
                                   site_links_archive => "\n",
                                   bootstrap_alt_theme => "darkly",
                                  },
                   button => 'edit_site');
is $site->site_links->count, 0;
is $site->get_from_storage->bootstrap_alt_theme, 'darkly', "Option set";
$mech->get_ok('/');
$mech->content_lacks('darkly');
$mech->get_ok('/?__switch_theme=1');
$mech->content_contains('darkly');
$mech->get_ok('/');
$mech->content_contains('darkly');
$mech->get_ok('/?__switch_theme=1');
$mech->content_lacks('darkly');

# start a new session
$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

$mech->get_ok('/');
$mech->content_lacks('darkly');
$mech->get_ok('/?__switch_theme=1');
$mech->content_contains('darkly');
$mech->get_ok('/');
$mech->content_contains('darkly');
$mech->get_ok('/?__switch_theme=1');
$mech->content_lacks('darkly');
