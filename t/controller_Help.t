use strict;
use warnings;
use Test::More tests => 5;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = $schema->resultset('Site')->find({ canonical => 'blog.amusewiki.org' });
{
    my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                   host => 'blog.amusewiki.org');

    $mech->get_ok('/help/opds');
    $mech->content_contains('/help/opds');
    $mech->content_contains('opds-1.png');
    $mech->follow_link_ok({ url_regex => qr{/opds$} });
    is $mech->uri->path, '/opds';
}
