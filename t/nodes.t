#!perl
use utf8;
use strict;
use warnings;
use Benchmark qw/timethis/;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Test::More tests => 2;

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";

use AmuseWiki::Tests qw/create_site/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0nodes1');

$site->update({ multilanguage => 'en it' });

{
    my $parent;
    foreach my $u (qw/one two three four five six seven eight/) {
        for my $id (0..1) {
            my $uri = "$u-$id";
            my $node = $site->nodes->create({ uri => $uri });
            $node->update_from_params({
                                       title_en => ucfirst($uri) . ' (en)',
                                       body_en => ucfirst($uri) . ' body EN',
                                       title_it => ucfirst($uri) . ' (it)',
                                       body_it => ucfirst($uri) . ' body IT',
                                       parent_node_uri => $parent ? $parent->uri : undef,
                                      });
            if ($id) {
                $parent = $node;
            }
        }
    }
}

my %expect = (
              en => [
                     'One-0 (en)',
                     'One-1 (en)',
                     'One-1 (en) / Two-0 (en)',
                     'One-1 (en) / Two-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en) / Eight-0 (en)',
                     'One-1 (en) / Two-1 (en) / Three-1 (en) / Four-1 (en) / Five-1 (en) / Six-1 (en) / Seven-1 (en) / Eight-1 (en)',
                    ],
              it => [
                     'One-0 (it)',
                     'One-1 (it)',
                     'One-1 (it) / Two-0 (it)',
                     'One-1 (it) / Two-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it) / Eight-0 (it)',
                     'One-1 (it) / Two-1 (it) / Three-1 (it) / Four-1 (it) / Five-1 (it) / Six-1 (it) / Seven-1 (it) / Eight-1 (it)',
                    ],
              
             );

foreach my $lang (qw/en it/) {
    my $list = $site->nodes->as_list_with_path($lang);
    my @out;
    foreach my $i (@$list) {
        push @out, $i->{title};
    }
    is_deeply(\@out, $expect{$lang});
}

