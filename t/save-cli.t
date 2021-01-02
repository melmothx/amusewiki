#!perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 14;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;
use Path::Tiny;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0savecli0';
my $site = create_site($schema, $site_id);
ok ($site);
$site->update({
               pdf => 1,
               a4_pdf => 1,
               lt_pdf => 1,
               sl_pdf => 1,
               secure_site => 0,
              });

{
    my $muse_file = path($site->repo_root, t => tt => 'test.muse');
    $muse_file->parent->mkpath;
    $muse_file->spew_utf8(<<'MUSE');
#title Test
#slides on

** Here we go

Body
MUSE
}

$site->jobs->delete;
$site->update_db_from_tree(sub { diag join(' ', @_) });
while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}


my $j = $site->jobs->enqueue(save_bb_cli => {}, 'root');

ok $j;

$j->dispatch_job;

ok -d path($site->repo_root, 'bin');
is scalar(path($site->repo_root, 'bin')->children), 4, "Found 4 scripts";

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/login');
$mech->submit_form(with_fields => {
                                   __auth_user => 'root',
                                   __auth_pass => 'root',
                                  });

$mech->get_ok('/settings/formats');
$mech->submit_form(with_fields => {
                                   format_name => 'EPUB with fonts',
                                  });

like $mech->uri, qr{formats/edit}, "New format created";

$mech->submit_form(with_fields => {
                                   format => 'epub',
                                   epub_embed_fonts => 1,
                                  },
                   button => "update",
                  );

is scalar(path($site->repo_root, 'bin')->children), 4, "Found 4 scripts";

while (my $j = $site->jobs->dequeue) {
    $j->dispatch_job;
    diag $j->logs;
}

is scalar(path($site->repo_root, 'bin')->children), 5, "Found 5 scripts";



foreach my $c (path($site->repo_root, 'bin')->children) {
    is system("$c", path($site->repo_root, t => tt => "test.muse")->stringify), 0, "$c executes fine";
}

