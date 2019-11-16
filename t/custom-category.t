#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 77;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper::Concise;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0cc0';

my $site = create_site($schema, $site_id);

foreach my $i (1..3) {
    my ($rev) = $site->create_new_text({
                                        title => "$i Hello $i",
                                        textbody => 'Hey',
                                       }, "text");
    my $preamble =<<"EOF";
#publisher Pinco $i, Pallino $i
#location Washington, DC; Zagreb, Croatia;
#season summer $i
EOF
    $rev->edit($preamble . $rev->muse_body);
    $rev->commit_version;
    $rev->publish_text;
}

ok $site->categories->count;
