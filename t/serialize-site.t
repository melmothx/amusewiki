#!perl

use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 28;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Storable qw/dclone/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site_id = '0serialize0';
my $site = create_site($schema, $site_id);

$site->add_to_vhosts({ name => 'pinco.pallino.net' });
$site->add_to_vhosts({ name => 'www.pallino.net' });
$site->add_to_site_options({ option_name => 'test', option_value => 'tvalue' });
$site->add_to_site_links({ url => 'http://www.example.org', label => 'Example' }) for (1..4);
$site->add_to_categories({ name => 'The Cat', uri => 'the-cat', type => 'topic' });
$site->add_to_redirections({ uri => 'test', type => 'topic', redirect => 'the-text' });
$site->add_to_legacy_links({ legacy_path => 'blablab', new_path => 'baf' });
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

$site->update({ secure_site => 0,
                pdf => 0,
                epub => 0,
                html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

{
    my $muse = <<'MUSE';
#title TITLE
#lang en
#topics the-cat

Test
MUSE
    my ($rev, $err) = $site->create_new_text({
                                              title => "title",
                                              lang => 'en',
                                             }, 'text');
    $rev->edit($muse);
    $rev->commit_version;
    $rev->publish_text;
    $mech->get_ok($rev->title->full_uri);
    $mech->get('/login');
    $mech->submit_form(with_fields => { __auth_user => 'punzo', __auth_pass => 'blabla' });
    $mech->get_ok('/bookbuilder/add/title');
    $mech->get_ok('/bookbuilder');
    my $sid;
    if ($mech->content =~ m{<span class="bb-token-id">(.*)</span>}) {
        $sid = $1;
    }
    ok ($sid, "Session id fount");
    $mech->submit_form(with_fields => {
                                       title => 'this is the bookbuilder title',
                                       schema => '1x4x2cutfoldbind',
                                      },
                       button => 'update');
    $mech->submit_form(form_id => 'bb-create-profile-form',
                       fields => { profile_name => 'profile with title' },
                       button => 'create_profile',
                      );
    $mech->get_ok('/logout');
    $mech->get_ok('/');
    $mech->get('/settings/formats');
    is $mech->status, '401';
    $mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
    is $mech->status, '200';
    my $name = "my custom format epub";
    $mech->submit_form(with_fields => {
                                       format_name => $name,
                                      });
    $mech->content_contains($name);
    $mech->submit_form(with_fields => {
                                       format_name => $name,
                                       format => 'epub',
                                      },
                       button => 'update',
                      );
    $mech->content_contains($name);
}

my $export = $site->serialize_site;

foreach my $check (qw/vhosts site_options categories redirections site_links/) {
    ok(scalar @{$export->{$check}}, "$check has something");
}

ok ($export->{categories}->[0]->{category_descriptions}, "Found category description");


diag Dumper($export);

# print Dumper($schema->resultset('Site')->find('0blog0')->serialize_site);

my $new = $schema->resultset('Site')->deserialize_site(dclone($export));
is_deeply($new->serialize_site, $export, "Updating self works");

$site->users->delete;
$site->delete;

$new = $schema->resultset('Site')->deserialize_site(dclone($export));
is_deeply($new->serialize_site, $export, "Reinserting the site works as well");

$new->add_to_users({ username => 'pippuozzu', password => 'xx' });
$new = $schema->resultset('Site')->deserialize_site(dclone($export));

# diag Dumper($new->serialize_site);
is (scalar(@{$export->{users}}), 2, "2 users imported");
my @users_found = $new->users;
is(scalar(@users_found), 3, "Found 3 users");

my $test_user = $schema->resultset('User')->update_or_create({ username => 'palmiro', password => 'pp' });

push @{$export->{users}}, { username => 'palmiro', password => 'pp' };
$new = $schema->resultset('Site')->deserialize_site(dclone($export));
my %site_users = map { $_->username => 1 } $new->users;
ok ($site_users{palmiro}, "palmiro found");
is_deeply(\%site_users, {
                         pippuozzu => 1,
                         xxx1xxx => 1,
                         punzo => 1,
                         palmiro => 1,
                        }, "users found");


foreach my $check (qw/vhosts
                      site_options
                      site_links
                      categories
                      legacy_links
                      redirections/) {
    ok $new->$check->first;
}

$test_user->delete;
$new->delete;
