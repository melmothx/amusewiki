#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 9;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper;
use Storable qw/dclone/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0serialize0';
my $site = create_site($schema, $site_id);

$site->add_to_vhosts({ name => 'pinco.pallino.net' });
$site->add_to_vhosts({ name => 'www.pallino.net' });
$site->add_to_site_options({ option_name => 'test', option_value => 'tvalue' });
$site->add_to_site_links({ url => 'http://www.example.org', label => 'Example' });
$site->add_to_categories({ name => 'The Cat', uri => 'the-cat', type => 'topic' });
$site->add_to_redirections({ uri => 'test', type => 'topic', redirect => 'the-text' });
$site->set_users([
                  {
                   username => 'punzo',
                   password => 'blabla',
                  },
                  {
                   username => 'xxx1xxx',
                   password => '12341234',
                  },
                 ]);
foreach my $user ($site->users) {
    $user->set_roles({ role => 'librarian' });
}
my $cat = $site->categories->find({ uri => 'the-cat', type => 'topic' });
$cat->add_to_category_descriptions({ lang => 'it',
                                     muse_body => 'add',
                                     html_body => '<p>add</p>', });

$site->discard_changes;
my $export = $site->serialize_site;

foreach my $check (qw/vhosts site_options categories redirections site_links/) {
    ok(scalar @{$export->{$check}}, "$check has something");
}

print Dumper($export);

# print Dumper($schema->resultset('Site')->find('0blog0')->serialize_site);

my $new = $schema->resultset('Site')->deserialize_site(dclone($export));
is_deeply($new->serialize_site, $export, "Updating self works");

$site->users->delete;
$site->delete;

$new = $schema->resultset('Site')->deserialize_site(dclone($export));
is_deeply($new->serialize_site, $export, "Reinserting the site works as well");

$new->add_to_users({ username => 'pippuozzu', password => 'xx' });
$new = $schema->resultset('Site')->deserialize_site(dclone($export));

diag Dumper($new->serialize_site);

my @users_found = $new->users;
is(scalar(@users_found), 3, "Found 3 users");
is (scalar(@{$new->serialize_site->{users}}), 2, "2 imported");

$new->delete;
