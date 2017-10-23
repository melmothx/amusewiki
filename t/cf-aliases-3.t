use utf8;
use strict;
use warnings;
use Test::More tests => 36;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Archive::BookBuilder;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Utils::Jobber;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;
my $site = create_site($schema, '0cformats0');
# check the after hook.
is $site->custom_formats->count, 4;
is $site->custom_formats->active_only->count, 0;

$site->check_and_update_custom_formats;
is $site->custom_formats->active_only->count, 0;

$site->update({
               secure_site => 0,
               pdf => 1,
               a4_pdf => 1,
               sl_pdf => 1,
               lt_pdf => 1,
              });
$site->check_and_update_custom_formats;
is $site->custom_formats->active_only->count, 4;

is $site->custom_formats->first->bb_mainfont, $site->mainfont;

$site->custom_formats->delete;

# check inheritance
$site->update({ mainfont => 'TeX Gyre Termes' });
$site->check_and_update_custom_formats;
is $site->custom_formats->active_only->count, 4;
is $site->custom_formats->search({ bb_mainfont => $site->mainfont })->count, 4;

my $admin = $site->update_or_create_user({ username => "test-admin",
                                           password => "test-admin" }, 'admin');

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
              
$mech->get('/settings/formats');
ok $mech->submit_form(with_fields => {__auth_user => 'test-admin', __auth_pass => 'test-admin' }) or die;
foreach my $cf ($site->custom_formats->all) {
    $mech->content_contains($cf->format_name);
    my $status = $cf->active;
    ok($mech->submit_form(form_id => 'format-activate-' . $cf->custom_formats_id));
    $cf->discard_changes;
    isnt $cf->active, $status, "$status was toogled with the inactive";
}
$mech->get_ok('/user/site');
$mech->submit_form(with_fields => { mainfont => 'Gentium Book Basic' },
                   button => 'edit_site');

$site->discard_changes;
is $site->mainfont, 'Gentium Book Basic';
$mech->get_ok('/settings/formats');
ok($mech->submit_form(with_fields => { format_name => 'Gentium' }));
my $gentium = $site->custom_formats->search({ format_name => 'Gentium' })->first;
is $site->custom_formats->search({ bb_mainfont => { '!=' => $site->mainfont }})->count, 4;
ok $gentium;
is $gentium->bb_mainfont, $site->mainfont;
$mech->follow_link(text => $gentium->format_name);
foreach my $format (qw/epub slides pdf/) {
    $mech->submit_form(with_fields => { format => $format },
                       button => 'update');
    $gentium->discard_changes;
    is ($gentium->bb_format, $format);
}
$mech->get_ok('/settings/formats');
$mech->submit_form(form_id => 'format-priority-' . $gentium->custom_formats_id,
                   fields => { priority => 2 });
is $gentium->discard_changes->format_priority, 2;
$mech->follow_link(text => $gentium->format_name);
$site->update({ mainfont => 'TeX Gyre Pagella' });
$mech->submit_form(with_fields => { format => 'epub' },
                   button => 'reset');
$gentium->discard_changes;
is ($gentium->bb_mainfont, $site->mainfont);
is ($gentium->bb_sansfont, $site->sansfont);
is ($gentium->bb_format, 'epub');
