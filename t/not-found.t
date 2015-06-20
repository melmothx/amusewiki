#!perl
use strict;
use warnings;
use Test::More tests => 12;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $blogsite = $schema->resultset('Site')->find('0blog0');
my $blogsite_name = $blogsite->sitename;
ok ($blogsite_name, "name is $blogsite_name");

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $expected = qr{\Q$blogsite_name\E\s*</title>}s;

$mech->get('/');
is ($mech->uri->path, '/special/index');
$mech->get('');
$mech->content_like($expected);
is ($mech->uri->path, '/special/index');
$mech->get('/aljkjsdflkk');
is $mech->status, '404';
$mech->content_like($expected);


my $site_id =  '0not0';
my $site = create_site($schema, $site_id);

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => '0not0.amusewiki.org');

my $sitename = 'This is a test sitename';
my $sitename_re = qr{\Q$sitename\E\s*</title>}s;
$site->update({ sitename => $sitename });
$mech->get('/');
$mech->content_like($sitename_re) or diag $mech->content;
is ($mech->uri->path, '/library');
$mech->content_like($sitename_re);
$mech->get('');
is ($mech->uri->path, '/library');
$mech->get('/lk9xc8olj');
is $mech->status, '404';
$mech->content_like($sitename_re);
