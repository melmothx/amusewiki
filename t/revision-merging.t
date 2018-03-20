#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 10;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Text::Amuse::Compile::Utils qw/read_file write_file/;
use Path::Tiny;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0revmerg0';
my $site = create_site($schema, $site_id);

{
    my $file = path($site->repo_root, qw/f ft first-test.muse/);
    $file->parent->mkpath;
    $file->spew_utf8(path(qw/repo 0blog0 f ft first-test.muse/)->slurp_utf8);
    foreach my $f (path(qw/repo 0blog0 f ft/)->children(qr{\.(png|jpe?g)})) {
        $f->copy($file->parent);
    }
    $site->update_db_from_tree(sub { diag @_ });
}

my $text = $site->titles->published_texts->find({ uri => 'first-test' });


my $revision = $text->new_revision;

# do a copy to avoid modifing our own git...
my $original_file = read_file($revision->title->f_full_path_name);


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

my $other_revision = $text->new_revision;

ok $other_revision->can_be_merged, "The other revision can be merged";

# publish

$revision->commit_version;
$revision->publish_text;


ok !$other_revision->can_be_merged, "The other revision now can't be merged";

# reset
my $restore = $text->new_revision;
$restore->edit($original_file);

ok $restore->can_be_merged, "New revision works";

$restore->commit_version;
$restore->publish_text;
