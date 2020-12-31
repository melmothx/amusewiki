#!perl

use utf8;
use strict;
use warnings;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
}

use Test::More tests => 66;
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
