use strict;
use warnings;
use Test::More tests => 15;
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
$mech->get_ok('/latest/2');
