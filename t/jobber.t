#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 81;
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

my $init = catfile(getcwd(), qw/script jobber.pl/);

system($init, 'restart');

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0job0';
my $site = create_site($schema, $site_id);
ok($site);
my $git = $site->git;
$git->remote(add => origin => '/tmp/blablabla.git');

my $host = $site->canonical;

my $testdir = File::Temp->newdir(CLEANUP => 1);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $host);

$mech->get_ok('/action/text/new');

ok($mech->form_id('login-form'), "Found the login-form");

$mech->set_fields(username => 'root',
                  password => 'root');
my $git_author = "Root <root@" . $host . ">";
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

my $editinglocation = $mech->response->base->path;

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


ok($mech->form_name('publish'));

$mech->click;

my $success = check_jobber($mech);

ok ($success) or die "No success can't proceed";
like $success->{logs}, qr/Created pippo-ciccia/;

$mech->get_ok("/tasks/status/$success->{id}");
$mech->content_contains($success->{logs});

ok $success->{produced};

my $text = $success->{produced} or die "Can't continue without a text";

$mech->get_ok($editinglocation);
$mech->content_contains("This revision is already published, ignoring changes");

$mech->form_id('museform');
$mech->submit;
$mech->content_contains("This revision is already published, ignoring changes");
is ($mech->response->base->path, $editinglocation, "Can't go further");

$mech->form_id('museform');
$mech->submit;
$mech->content_contains("This revision is already published, ignoring changes");
is ($mech->response->base->path, $editinglocation, "Can't go further");


$mech->get('/');
$mech->content_contains($title);
$mech->get_ok($text);
$mech->content_contains(q{<h3 id="text-author">pippo</h3>});
ok($mech->form_id('book-builder-add-text'));
$mech->click;

$mech->content_contains("The text was added to the bookbuilder");
is ($mech->uri->path, $text);
$mech->get_ok("/bookbuilder");

$mech->form_with_fields('signature');

$mech->field(title => 'test');
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

like $gitop->{logs}, qr/fatal\:/,  "git job works but fails";
like $gitop->{logs}, qr/(does not appear to be a git repository|Could not read from remote repository)/, "Found message";



diag "trying the deletion";

$mech->get_ok('/action/text/new');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");

$title = 'cacca ' . int(rand(1000));
$mech->set_fields(author => 'bobi',
                  title => $title,
                  textbody => 'bau');

$mech->click;

$mech->content_contains('Created new text');
$title =~ s/ /-/;

like $mech->response->base->path, qr{^/action/text/edit/bobi-\Q$title\E}, "Location matches";

$mech->form_id('museform');
$mech->field(body => "#title $title\n#author bobi\n#lang en\n#DELETED null\n\nbau\n");
$mech->click('commit');

$mech->content_contains('Changes committed') or diag $mech->response->content;

ok($mech->form_name('publish'));

$mech->click;

$success = check_jobber($mech);

$text = $success->{produced} or die "Can't continue without a text";

{
    my ($log) = $git->log;
    ok($log->message) and diag $log->message;
    is($log->attr->{author}, $git_author, "author set correctly");
}


my $text_file = catfile($site->repo_root,
                        qw/b bc/, "bobi-$title.muse");

ok (-f $text_file, "$text_file is present");


$mech->get($text);

is $mech->status, '404', "deleted text not found";

$mech->get_ok('/console/unpublished');

ok ($mech->form_name('purge'), "Found purging form");

my $text_row = $schema->resultset('Title')
  ->single({ f_full_path_name => $text_file });
ok ($text_row, "$text_file found");

$mech->click;

check_jobber($mech);

{
    my ($log) = $git->log;
    is $log->message, "$text deleted by root\n", "Deletion found in the git";
    is $log->attr->{author}, $git_author, "author set correctly";
}

$text_row = $schema->resultset('Title')
  ->single({ f_full_path_name => $text_file });
ok (!$text_row, "$text_file not found");
ok (! -f $text_file, "$text_file is no more");

sub check_jobber {
    my $mech = shift;
    like $mech->response->base->path, qr{^/tasks/status/}, "Location for tasks ok";
    my $task_path = $mech->response->base->path;
    my ($task_id) = $task_path =~ m{^/tasks/status/(.*)};
    ok $task_id;
    diag "Waiting for the jobber to react";
    my $success;
    for (1..30) {
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
    diag Dumper($success);
    return $success;
}

