#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 47;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Cwd;
use File::Spec::Functions qw/catdir catfile/;
use File::Temp;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use JSON qw/decode_json/;
use Data::Dumper;

diag "(Re)starting the jobber";

my $init = catfile(getcwd(), 'init-jobs.pl');

system($init, 'restart');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0job0';
my $site = create_site($schema, $site_id);
ok($site);
my $git = $site->git;
$git->remote(add => origin => '/tmp/blablabla.git');


my $host = $site->vhosts->first->name;

my $testdir = File::Temp->newdir(CLEANUP => 0);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$mech->get_ok('/action/text/new');

ok($mech->form_id('login-form'), "Found the login-form");

$mech->set_fields(username => 'root',
                  password => 'root');
$mech->click;

$mech->content_contains('You are logged in now!');


diag "Uploading a text";
my $title = 'ciccia ' . int(rand(1000));
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => $title,
                  textbody => "Hello <em>there</em>\n");
$mech->click;

$mech->content_contains('Created new text');
$title =~ s/ /-/;

like $mech->response->base->path, qr{^/action/text/edit/pippo-\Q$title\E}, "Location matches";

$mech->content_like(qr/\#title\s* ciccia.*
                       \#author\s* pippo.*
                       \#lang\s* en.*
                       \#pubdate.*
                       Hello.*there/xs, "Found muse body")
  or diag $mech->response->content;

$mech->form_id('museform');

$mech->field(body => "Hello there");

$mech->click('commit');

$mech->content_contains('Missing #title header in the text!');

ok($mech->form_id('museform'), "Found form again");

$mech->field(body => "#title ciccia\n#author pippo\n#lang en\n\nHello there\n");

$mech->click('commit');

$mech->content_contains('Changes committed') or diag $mech->response->content;


ok($mech->form_with_fields('publish'));

$mech->click;

my $success = check_jobber($mech);

ok ($success) or die "No success can't proceed";
like $success->{logs}, qr/Created pippo-ciccia/;

$mech->get_ok("/tasks/status/$success->{id}");
$mech->content_contains($success->{logs});

ok $success->{produced};

my $text = $success->{produced} or die "Can't continue without a text";

$mech->get('/');
$mech->content_contains($title);
$mech->get_ok($text);
$mech->content_contains(q{<h3 id="text-author">pippo</h3>});
ok($mech->form_id('book-builder-add-text'));
$mech->click;

$mech->content_contains("The text was added to the bookbuilder");
is ($mech->uri->path, $text);
$mech->get_ok("/bookbuilder");

$mech->form_with_fields('collectionname');

$mech->field(collectionname => 'test');
$mech->click;

my $bbres = check_jobber($mech);

ok(exists $bbres->{errors}, "Error field exists");
ok(!$bbres->{errors}, "Error field exists but empty");
like $bbres->{logs}, qr/Created pippo-ciccia.*pdf/;
like $bbres->{produced}, qr/\.pdf$/;
$mech->get_ok($bbres->{produced});

$mech->get_ok('/console/git');

ok($mech->form_with_fields('action'));
$mech->click;

my $gitop = check_jobber($mech);

like $gitop->{logs}, qr/fatal: The remote end hung up unexpectedly/,
  "git job works";

sub check_jobber {
    my $mech = shift;
    like $mech->response->base->path, qr{^/tasks/status/}, "Location for tasks ok";
    my $task_path = $mech->response->base->path;
    my ($task_id) = $task_path =~ m{^/tasks/status/(.*)};
    ok $task_id;
    diag "Waiting for the jobber to react";
    my $success;
    for (1..20) {
        $mech->get("/tasks/status/$task_id/ajax");
        my $ajax = decode_json($mech->response->content);
        if ($ajax->{status} eq 'completed') {
            $success = $ajax;
            last;
        }
        elsif ($ajax->{status} eq 'failed') {
            diag "Job failed!\n";
            diag $ajax->{errors};
            return;
        }
        diag "Nothing yet...$ajax->{status}";
        sleep 1;
    }
    ok($success);
    is $success->{status}, 'completed';
    is $success->{site_id}, $site_id;
    print Dumper($success);
    return $success;
}

