#!perl

use utf8;
use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;


my $schema = AmuseWikiFarm::Schema->connect('amuse');
$schema->resultset('Job')->delete;
my $site = create_site($schema, '0deadlock0');
$site->update({ pdf => 1 });
$site->check_and_update_custom_formats;

{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                              }, 'text');
    die $err if $err;
    $rev->edit($rev->muse_body . "\n\n some more text for the masses\n");
    $rev->commit_version;
    $rev->publish_text;
}

$ENV{PATH} = '/bin';

while (my $j = $schema->resultset('Job')->dequeue) {
    $j->dispatch_job;
    ok $j->logs;
}
done_testing;


