#!perl

use strict;
use warnings;

use Test::More tests => 34;
use Cwd;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site start_jobber stop_jobber/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;

my $site_id = '0confl0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
$site->mode('modwiki');
$site->magic_question('Hu?');
$site->magic_answer('Hu?');
$site->update;

my $jpid = start_jobber($schema);
diag "Jobber pid is $jpid";

my $mechone = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

my $mechtwo = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

my $created;
foreach my $mech ($mechone, $mechtwo) {
    $mech->get_ok('/');
    $mech->get('/action/text/new');
    ok($mech->form_with_fields('__auth_human'));
    $mech->field(__auth_human => 'Hu?');
    $mech->click;
    is $mech->status, 200;
    ok($mech->form_with_fields('title'));
    $mech->field('title' => 'hello');
    $mech->click;

    if (!$created) {
        $created = $mech->uri->path;
        like $created, qr{/action/text/edit/hello/}, "Path looks correct";
        $mech->form_with_fields('body');
        ok($mech->click('commit'));
        $mech->content_contains('Changes saved, thanks');

    }
    else {
        is $mech->uri->path, '/action/text/new', "Creation failed ok";
        $created =~ s/[0-9]+$//;
        $mech->get_ok($created, "Visiting $created");
        $mech->content_contains('Some ongoing revisions were found');
        ok(!$mech->form_with_fields('create'), "Creation is not offered");
        is $mech->status, '200';
        $mech->get_ok("$created?create=1");
        $mech->content_contains('Some ongoing revisions were found');
        $mech->content_contains('text has not been published yet');
    }
}

$created = '';

foreach my $mech ($mechone, $mechtwo) {
    if (!$created) {
        $mech->get_ok('/action/text/new');
        ok($mech->form_with_fields('title'));
        $mech->field('title' => 'hulloz');
        $mech->click;
        $created = $mech->uri->path;
        like $created, qr{/action/text/edit/hulloz/}, "Path looks correct";
        $mech->content_contains('Created new text');
    }
    else {
        $created =~ s/[0-9]+$//;
        $mech->get_ok($created, "Visiting $created");
        $mech->content_contains('Some ongoing revisions were found');
        # count the links
        my @links = grep { $_->url =~ m!\Q$created\E[0-9]+$! } $mech->links;
        is (scalar(@links), 1, "Found 1 link") or diag Dumper($mech->links);
        $mech->content_contains('This revision is being actively edited');
        $mech->content_contains('text has not been published yet');
        ok(!$mech->form_with_fields('create'), "Creation is not offered");

        $mech->get_ok("$created?create=1");
        @links = grep { $_->url =~ m!\Q$created\E[0-9]+$! } $mech->links;
        is (scalar(@links), 1, "Found 1 link");
        $mech->content_contains('This revision is being actively edited');

        $mech->content_contains('Some ongoing revisions were found');
        $mech->content_contains('text has not been published yet');
    }
}

diag "Killin $jpid";
stop_jobber($jpid);


