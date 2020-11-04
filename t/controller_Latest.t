use strict;
use warnings;
use Test::More tests => 41;
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
my $site = create_site($schema, '0latest0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

my $guard = $schema->txn_scope_guard;
foreach my $month (1..12) {
    foreach my $day (1..27) {
        my $uri = "title-$month-$day";
        my $title = $site->titles->create({
                                           title => "A test $day $month",
                                           uri => $uri,
                                           pubdate => DateTime->new(year => 2015, month => $month, day => $day),
                                           f_path => $uri,
                                           f_name => $uri,
                                           f_archive_rel_path => "t/t$day",
                                           f_timestamp => 0,
                                           f_full_path_name => $uri,
                                           f_suffix => "muse",
                                           f_class => 'text',
                                           status => 'published',
                                          });
    }
}
$guard->commit;
my $text = $site->titles->first;
foreach my $lang (sort keys (%{ $site->known_langs })) {
    ok($text->pubdate_locale($lang), "$lang: " . $text->pubdate_locale($lang));
}


$mech->get_ok('/latest');
$mech->get_ok('/latest/1');
$mech->content_contains(q{rel="next"});
$mech->content_lacks(q{rel="prev"});
$mech->content_contains('Dec 27, 2015');
$mech->content_contains('Dec 18, 2015');
$mech->get_ok('/latest/2');
$mech->content_contains(q{rel="next" href="http://0latest0.amusewiki.org/latest/3"});
$mech->content_contains(q{rel="prev" href="http://0latest0.amusewiki.org/latest/1"});
$mech->content_contains('Dec 17, 2015');
$mech->content_contains('Dec 8, 2015');
# pagination
$mech->content_contains('/latest/33');
$mech->content_contains('/latest/4');
$mech->content_contains('/latest/1');
# check
$mech->get_ok('/latest/33');
$mech->content_contains('Jan 1, 2015');
$mech->content_lacks(q{rel="next"});
$mech->content_contains(q{rel="prev"});

my @links = grep { $_->url =~ m{/(latest|library)} }
  $mech->find_all_links;
$mech->links_ok(\@links);
# diag Dumper(\@links);
ok(scalar(@links), "Found and tested " . scalar(@links) . " links");

$mech->get_ok('/opds');

