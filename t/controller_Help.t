use strict;
use warnings;
use Test::More tests => 3;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

$mech->get_ok('/help/opds');
$mech->follow_link_ok({ url_regex => qr{/opds$} });
is $mech->uri->path, '/opds';
