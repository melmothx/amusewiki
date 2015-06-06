#!perl

use strict;
use warnings;
use Test::More tests => 57;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Cwd;
use File::Spec::Functions qw/catdir catfile/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Archive::Cache;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use File::Find;

diag "(Re)starting the jobber";

my $init = catfile(getcwd(), qw/script jobber.pl/);

system($init, 'restart');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0deferred0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0 });

my $host = $site->canonical;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$mech->get_ok('/action/text/new');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;
$mech->content_contains('You are logged in now!');
$mech->get_ok('/action/text/new');

foreach my $spec ({
                   title => 'deferred-text',
                   author => 'pippo',
                   pubdate => '2024-10-10',
                   status => 'deferred'
                  },
                  {
                   title => 'deleted-text',
                   author => 'pippo',
                   pubdate => '2010-10-10',
                   status => 'deleted'
                  }) {
    diag "Uploading a text";
    $mech->get_ok('/action/text/new') or die $mech->status . $mech->path;
    my $uri = $spec->{author} . '-'. $spec->{title};
    my $full_uri = "/library/$uri";
    ok($mech->form_id('ckform')) or die $mech->status . ' ' . $mech->uri->path;

    $mech->set_fields(author => $spec->{author},
                      title => $spec->{title},
                      pubdate => $spec->{pubdate},
                      textbody => "Hello <em>there</em>\n");
    $mech->click;
    $mech->content_contains('Created new text');
    my $pubdate_re = $spec->{pubdate};
    $pubdate_re =~ s/-10$//;
    $mech->content_like(qr/\#title\s*\Q$spec->{title}\E.*
                           \#author\s*\Q$spec->{author}\E.*
                           \#lang\s*en.*
                           \#pubdate\s*\Q$pubdate_re\E.*
                           Hello.*there/xs, "Found muse body")
      or diag $mech->response->content;

    $mech->form_id('museform');
    if ($spec->{status} eq 'deleted') {
        my $muse =<<"MUSE";
#title $spec->{title}
#author $spec->{author}
#lang en
#pubdate $spec->{pubdate}
#DELETED nuked

Hello <em>there</em>

MUSE
        $mech->field(body => "$muse");
    }
    $mech->click('commit');
    $mech->content_contains('Changes committed') or diag $mech->response->content;
    ok($mech->form_name('publish'));
    $mech->click;
    diag "waiting 10 seconds for compilation, should be enough";
    sleep 10;

    if ($spec->{status} eq 'deferred') {
        $mech->get_ok($full_uri);
        $mech->content_contains('This text is not published yet');
    }
    elsif ($spec->{status} eq 'deleted') {
        $mech->get($full_uri);
        is $mech->status, '404', "Status is 404 for deleted";
    }
    $mech->get_ok('/console/unpublished');
    $mech->content_contains($full_uri);
    $mech->content_contains($pubdate_re);
    $mech->follow_link_ok({ text => $full_uri });
}

my $cache = AmuseWikiFarm::Archive::Cache->new;
$cache->clear_all;
my @cache_files = check_cache($cache->cache_dir);
ok(!@cache_files, "Cache is clean") or diag Dumper(\@cache_files);

$mech->get_ok('/library');
$mech->content_contains('/library/pippo-deferred-text');
$mech->content_lacks('/library/pippo-deleted-text');
$mech->get_ok('/logout');

diag "Logging out and checking listing again";
diag $mech->uri->path;
@cache_files = check_cache($cache->cache_dir);
ok(!@cache_files, "Cache is clean") or diag Dumper(\@cache_files);

$mech->get_ok('/library');
$mech->content_lacks('/library/pippo-deferred-text');
$mech->content_lacks('/library/pippo-deleted-text');
$mech->get('/library/pippo-deferred-text');
is $mech->status, '404', "deferred not found";

@cache_files = check_cache($cache->cache_dir);
ok(!!@cache_files, "Cache is created") or diag Dumper(\@cache_files);

$mech->get_ok('/login');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;
$mech->content_contains('You are logged in now!');

$mech->get_ok('/library');
$mech->content_contains('/library/pippo-deferred-text');
$mech->content_lacks('/library/pippo-deleted-text');
$mech->get_ok('/logout');

diag "Logging out and checking listing again";

$mech->get_ok('/library');
$mech->content_lacks('/library/pippo-deferred-text');
$mech->content_lacks('/library/pippo-deleted-text');
$mech->get('/library/pippo-deferred-text');
is $mech->status, '404', "deferred not found";

system($init, 'stop');

# $site->delete;

sub check_cache {
    my $dir = shift;
    my @files;
    find sub { push @files, $_ if -f $_ }, $dir;
    return @files;
}

is ($site->titles->published_all->count, 0, "0 published");
is ($site->titles->published_or_deferred_all->count, 1, "1 deferred");
is ($site->titles->published_or_deferred_texts->first->status, 'deferred');
is ($site->titles->published_or_deferred_texts->count, 1);
is ($site->titles->published_or_deferred_specials->count, 0);
is ($site->titles->published_texts->count, 0);
is ($site->titles->published_specials->count, 0);
is ($site->titles->published_or_deferred_texts
    ->single({ uri => 'pippo-deferred-text' })->status, 'deferred');
