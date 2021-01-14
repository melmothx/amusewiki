#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 17;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0newheaders0';

my $site = create_site($schema, $site_id);

my %headers = (
               publisher => 'Publisher',
               isbn => '1234123412341234',
               rights => 'Copywrite (C)',
               seriesname =>  'My book series',
               seriesnumber => 'N. 10',
              );

$site->update({ secure_site => 0 });
{
    my ($rev, $err) =  $site->create_new_text({ author => 'pinco',
                                                title => 'pallino',
                                                lang => 'en',
                                                %headers,
                                                textbody => '<p>Text body</p>',
                                              }, 'text');
    die $err if $err;
    $rev->commit_version;
    $rev->publish_text;
}

my $title =  $site->titles->first;
is $title->isbn, '1234123412341234';
is $title->rights, 'Copywrite (C)';
is $title->seriesnumber, 'N. 10';
is $title->seriesname, 'My book series';

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/');
foreach my $url ('/library/pinco-pallino', '/library/pinco-pallino.html') {
    $mech->get_ok($url);
    foreach my $v (values %headers) {
        $mech->content_contains($v);
    }
}


