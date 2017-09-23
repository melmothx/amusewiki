#!/perl

use utf8;
use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 19;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use AmuseWikiFarm::Archive::Lexicon;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0crashloc0');

my ($rev) = $site->create_new_text({ uri => 'crashy', title => 'Crash' }, 'text');
$rev->edit("#topics my stuff [asdf]\n" . $rev->muse_body);
$rev->commit_version;
my $uri = $rev->publish_text;
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$mech->get_ok('/library/crashy');
$mech->content_contains('[asdf]');
$mech->get_ok('/category/topic');
$mech->content_contains('[asdf]');
$mech->get_ok('/category/topic/my-stuff-asdf');
$mech->content_contains('[asdf]');

my $model = AmuseWikiFarm::Archive::Lexicon->new;

my @strings = ('[hello]', '%hullo', "I ate [quant,_1,rhubarb pie].",
               "~[hullo~]", "~ ~", "~[~ hullo ~]~ [hullo]", "[garbage] [garbage]",
               "~[garbage~] ~[garbage~]",
               "~~[garbage~~] ~~[garbage~~]",
               "[", "~home", "~]", "~[",
              );
foreach my $string (@strings) {
    is $string, $model->localizer->loc($string), "$string pass ok";
}
