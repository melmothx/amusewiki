#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 10;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Path::Tiny;
use File::Copy qw/copy move/;
use Storable qw/dclone/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Site')->search({ canonical => '0ser0.amusewiki.org' })->delete;

my $site_id = '0ser0';
my $dump;
my $cfs;
my $old_tree;
{
    my $site = create_site($schema, $site_id);

    $site->add_to_vhosts({ name => 'pinco.pallino.net' });
    $site->add_to_vhosts({ name => 'www.pallino.net' });
    $site->add_to_site_options({ option_name => 'test', option_value => 'tvalue' });
    $site->add_to_site_links({ url => 'http://www.example.org', label => 'Example' }) for (1..4);
    $site->add_to_categories({ name => 'The Cat', uri => 'the-cat', type => 'topic' });
    $site->add_to_redirections({ uri => 'test', type => 'topic', redirect => 'the-text' });
    $site->add_to_legacy_links({ legacy_path => 'blablab', new_path => 'baf' });
    $site->add_to_site_category_types({
                                       category_type => 'location',
                                       name_singular => 'Location',
                                       name_plural => 'Locations',
                                      });
    $site->set_users([
                      {
                       username => 'xpunzo',
                       password => 'blabla',
                      },
                      {
                       username => 'xxx6xxx',
                       password => '12341234',
                      },
                     ]);
    foreach my $user ($site->users) {
        $user->set_roles({ role => 'librarian' });
    }

    my $muse = path($site->repo_root, t => tt => 'test.muse');
    $muse->parent->mkpath;
    $muse->spew_utf8(<<'MUSE');
#title Test
#lang it
#topics The Cat

It has an attachment

[[t-t-test-1.png]]

MUSE
    copy(catfile(qw/t files shot.png/),
         catfile($site->repo_root, qw/t tt t-t-test-1.png/));

    $site->update_db_from_tree;

    is $site->attachments->count, 1;
    my $att = $site->attachments->first;
    $att->edit(title_muse => "ciao",
               comment_muse => "hullo *there*");

    my $cat = $site->categories->find({ uri => 'the-cat', type => 'topic' });
    $cat->add_to_category_descriptions({
                                        lang => 'it',
                                        muse_body => 'add',
                                        html_body => '<p>add</p>',
                                       });
    ok $site->custom_formats->count;
    $site = $site->get_from_storage;
    $dump = $site->serialize_site;
    $cfs = [ map { $_->code } $site->custom_formats->sorted_by_priority ];
    $site->delete;
    ok -d $site->repo_root;
    $old_tree = $site->repo_root;
}

is $schema->resultset('Attachment')->search({ site_id => $site_id })->count, 0;
is $schema->resultset('CustomFormat')->search({ site_id => $site_id })->count, 0;

$dump->{id} = '0resurrect0';

# so with sqlite the CFs primary keys are not reused.
my $placeholder = create_site($schema, "0blabla");

{
    my $site = $schema->resultset('Site')->deserialize_site(dclone($dump));
    $site = $site->get_from_storage;
    is $site->id, '0resurrect0';
    is $schema->resultset('CustomFormat')->search({ site_id => $site->id })->count, 4;
    is $site->site_category_types->count, 3;

    # move the tree over.
    path($site->repo_root)->remove_tree({ verbose => 1, safe => 0 });
    move($old_tree, $site->repo_root);
    $site->update_db_from_tree;

    # reimport again
    $site = $schema->resultset('Site')->deserialize_site(dclone($dump));

    is $site->attachments->count, 1;
    my $att = $site->attachments->first;
    ok $att->comment_muse, "attachment comment brought over";
    ok $att->title_muse, "attachment title brought over";
    is_deeply [ map { $_->code } $site->custom_formats->sorted_by_priority ], $cfs,
      "Custom formats retained thery code";
}
diag Dumper($dump);

$placeholder->delete;
