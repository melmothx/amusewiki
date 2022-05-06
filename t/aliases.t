#!perl

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use utf8;
use strict;
use warnings;
use Test::More tests => 27;
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
    my $att = $rev->add_attachment('t/files/big.jpeg');
    $rev->edit($rev->muse_body . "\n\nOriginal body\n[[$att->{attachment}]]\n[[$att->{attachment}]]\n");
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

diag Dumper($site->my_title_uris);

{
    my $text_id = $site->my_title_uris->[0]->{id};
    my $orig_uri = $site->my_title_uris->[0]->{uri};
    my $uri = 'renamed-to-this';
    is $site->attachments->count, 4;
    my $job = $site->jobs->enqueue(rename_uri => { id => $text_id, uri => 'renamed-to-this' });
    $job->dispatch_job;
    diag $job->logs;
    is $site->attachments->count, 5;
    $mech->get_ok("/library/$uri");
    is $mech->uri->path, "/library/renamed-to-this";

    $mech->get_ok("/library/$uri.html");
    $mech->content_like(qr{src="r-t-renamed-to-this-1.jpg".*src="r-t-renamed-to-this-1.jpg"}si);
    $mech->get_ok("/library/r-t-renamed-to-this-1.jpg");
    foreach my $att ($site->attachments) {
        diag $att->full_uri;
        $mech->get_ok($att->full_uri);
    }
}

diag Dumper($site->my_title_uris);
