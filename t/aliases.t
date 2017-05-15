#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More tests => 15;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0aliases0';
my $site = create_site($schema, $site_id);
$site->update({ secure_site => 0,
                mode => 'blog',
              });

foreach my $i (0..3) {
    my ($rev) = $site->create_new_text({ uri => "try-$i",
                                         title => "Try #1",
                                         author => "author-$i",
                                         SORTtopics => "topic-$i",
                                         lang => 'en',
                                       }, 'text');
    $rev->commit_version;
    $rev->publish_text;
}
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get('/console/alias');
ok($mech->form_id('login-form'), "Found the login-form");
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });

my @private;
foreach my $type (qw/author topic/) {
    $mech->get_ok('/console/alias');
    $mech->submit_form(form_id => "alias-create-$type",
                       fields => {
                                  src => 'author-1',
                                  dest => 'author-2',
                                 });
    my $url = $mech->uri->path;
    diag $url;
    $site->jobs->dequeue->dispatch_job;
    push @private, $url;
}

foreach my $redir ($site->redirections) {
    $mech->get_ok('/console/alias');
    $mech->submit_form(form_id => 'alias-delete-' . $redir->id);
    my $url = $mech->uri->path;
    diag $url;
    $site->jobs->dequeue->dispatch_job;
    push @private, $url;
}

foreach my $url (@private) {
    $mech->get_ok($url);
}

$mech->get_ok('/logout');

foreach my $url (@private) {
    $mech->get($url);
    is $mech->status, 404;
}



diag Dumper(\@private);

