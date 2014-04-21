#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 10;
use AmuseWikiFarm::Archive;
use AmuseWikiFarm::Schema;
use File::Slurp qw/read_file write_file/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find('0blog0');

my $revision = $site->new_revision_from_uri('first-test');

# do a copy to avoid modifing our own git...
my $original_file = read_file($revision->title->f_full_path_name,
                             { binmode => ':encoding(UTF-8)'});

ok ($revision->id);
like $revision->f_full_path_name, qr/first-test\.muse$/, "Found the revision"
  and diag $revision->f_full_path_name;
like $revision->title->f_full_path_name, qr/first-test\.muse$/
  and diag $revision->title->f_full_path_name;
is $revision->status, 'editing', "status is editing";

$revision->edit("#title Another first test\n\nbla bla bla\n");

ok $revision->editing;
ok $revision->editing_ongoing;

ok $revision->can_be_merged, "Revision can be merged";

# create another one

my $other_revision = $site->new_revision_from_uri('first-test');

ok $other_revision->can_be_merged, "The other revision can be merged";

# publish

my $archive = AmuseWikiFarm::Archive->new(code => $site->id,
                                          dbic => $schema);

$archive->publish_revision($revision->id);


ok !$other_revision->can_be_merged, "The other revision now can't be merged";

# reset
my $restore = $site->new_revision_from_uri('first-test');
$restore->edit($original_file);

ok $restore->can_be_merged, "New revision works";

$archive->publish_revision($restore->id);
