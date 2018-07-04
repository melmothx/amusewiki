#!perl

use strict;
use warnings;

use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Text::Amuse::Compile::Utils qw/write_file read_file/;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Catalyst::Test 'AmuseWikiFarm';
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0crash202');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get_ok('/latest?__language=it');
$site->add_to_vhosts({ name => $site->canonical });
$site->update({ canonical => 'testmeagain.amusewiki.org' });
$mech->get('/');
is $mech->status, '301';

