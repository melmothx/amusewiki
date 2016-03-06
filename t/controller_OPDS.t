use strict;
use warnings;
use Test::More;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf-8)";
binmode $builder->failure_output, ":encoding(utf-8)";
binmode $builder->todo_output,    ":encoding(utf-8)";
binmode STDOUT, ":encoding(utf-8)";

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $cats = $schema->resultset('Site')->find('0blog0')->categories->active_only;

my @urls;
while (my $cat = $cats->next) {
    push @urls, { url => '/opds/' . $cat->type . 's/' . $cat->uri,
                  contains => $cat->name,
                };
    push @urls, { url => '/opds/' . $cat->type . 's/' . $cat->uri  . '/1',
                  contains => $cat->name,
                };
}

foreach my $url ({ url => '/opds' },
                 { url => '/opds/new' },
                 { url => '/opds/new/1' },
                 { url => '/opds/titles' },
                 { url => '/opds/titles/1' },
                 { url => '/opds/topics' },
                 { url => '/opds/authors' },
                 @urls,
                ) {
    $mech->get_ok($url->{url});
    is $mech->content_type, "application/atom+xml";
    if (my $contains = $url->{contains}) {
        $mech->content_contains($contains);
    }
    diag $mech->content if $url->{verbose};
}
done_testing;
