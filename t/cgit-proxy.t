#!perl

use strict;
use warnings;

use AmuseWikiFarm::Archive::CgitProxy;
use Test::More tests => 23;
use Data::Dumper;
use URI;

my $proxy = AmuseWikiFarm::Archive::CgitProxy->new;

is $proxy->create_uri, 'http://localhost:9015/git', "create_uri works";

uri_correct({port => 80}, ['commit'], { id => '12341234' },
            'http://localhost:80/git/commit?id=12341234');

uri_correct({}, [qw/commit test/], { bar => '12341234',
                                 foo => '1234' },
            'http://localhost:9015/git/commit/test?bar=12341234&foo=1234');

uri_correct({ port => 8080 }, [qw/commit test/], { bar => '12341234',
                                 foo => '1234' },
            'http://localhost:8080/git/commit/test?bar=12341234&foo=1234');

uri_correct({
             port => 8080,
             host => 'blabla',
             base_path => 'test',
             scheme => 'https',
            },
            [qw/commit test/],
            {
             bar => '12341234',
             foo => '1234'
            },
            'https://blabla:8080/test/commit/test?bar=12341234&foo=1234');

sub uri_correct {
    my ($constructor, $path, $params, $expected) = @_;
    my $proxy = AmuseWikiFarm::Archive::CgitProxy->new(%$constructor);
    my $uri = $proxy->create_uri($path, { %$params });
    my $got = URI->new($uri);
    my $exp = URI->new($expected);
    foreach my $m (qw/port host scheme path/) {
        is $got->$m, $exp->$m, "$m match: " . $got->$m;
    }
    is_deeply ($params, { $got->query_form }, "Params match");
}

SKIP: {
    skip "CGIT proxy is disabled", 1 if $proxy->disabled;
    my $html = $proxy->get([], { s => 'desc' })->html;
    like $html, qr/Name.*Description.*Idle/,
      "found content";
    ok !$proxy->get->disposition, "No disposition found";
};

