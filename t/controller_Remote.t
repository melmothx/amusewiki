#!perl
use strict;
use warnings;
use utf8;
use Test::More tests => 34;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Data::Dumper::Concise;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Utils::Amuse qw/from_json/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, '0api0');
$site->update({ secure_site => 0 });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm', host => $site->canonical);
$site->jobs->delete;

my %params =  (
               title => '<em>Prova</em> and <b>Prova</b>',
               author => 'Pinco',
               textbody => '<p>This is a <em>test</em></p> <p><b>Hello</b></p>',
              );
my %auth = (
            __auth_user => 'root',
            __auth_pass => 'root',
           );

{
    $mech->post('/remote/create/', { %params, %auth });
    my $res = from_json($mech->content);
    ok $res->{job};
    ok $res->{url};
    $mech->get_ok($res->{job});
    $mech->get($res->{url});
    is $mech->status, 404, "Too early, text not produced";
    diag Dumper($res);
    ok $site->jobs->count;
    while (my $j = $site->jobs->dequeue) {
        $j->dispatch_job;
        diag $j->logs;
    }
    $mech->get_ok($res->{url});
    $mech->get_ok($res->{url} . '.muse');
    diag $mech->content;
}

# try again, this one will fail with 401, no auth
{
    $mech->post('/remote/create/', { %params });
    is $mech->status, 401;
}

# try again, this one will fail with 401, no params
{
    $mech->post('/remote/create/', { %auth });
    my $res = from_json($mech->content);
    is $mech->status, 200;
    ok !$res->{url};
    ok !$res->{job};
    ok $res->{error};
    diag Dumper($res);
}


{
    $mech->post('/remote/create/', {%params, %auth} );
    my $res = from_json($mech->content);
    is $mech->status, 200;
    ok !$res->{url};
    ok !$res->{job};
    ok $res->{error};
    diag Dumper($res);
}

{
    $mech->post('/remote/create/special', {
                                           %auth,
                                           title => 'test',
                                           body => 'prova',
                                          });
    my $res = from_json($mech->content);
    diag Dumper($res);
}

$site->jobs->delete;

foreach my $type (qw/library special/) {
    my $res;
    my $body = "#title bau\n\nThis is a test";
    $mech->post("/remote/create/$type", {
                                         %auth,
                                         title => 'API Test',
                                         textbody => '<p>This is a <em>test</em></p> <p><b>Hello</b></p>',
                                        });
    $res = from_json($mech->content);
    diag Dumper($res);

    while (my $job = $site->jobs->dequeue) {
        $job->dispatch_job;
    }
    $mech->post("/remote/edit/$type/testxx", {
                                              %auth,
                                              body => $body,
                                              message => "Here we go",
                                             });
    $res = from_json($mech->content);
    diag Dumper($res);
    is $res->{error}, "This text does not exist";

    # som ete
    $mech->post("/remote/edit/$type/api-test", {
                                              %auth,
                                              body => $body,
                                             });
    $res = from_json($mech->content);
    diag Dumper($res);
    ok $res->{error};

    $mech->post("/remote/edit/$type/api-test", {
                                              %auth,
                                             });
    $res = from_json($mech->content);
    diag Dumper($res);
    ok $res->{error};

    $mech->post("/remote/edit/$type/api-test", {
                                                %auth,
                                                body => $body,
                                                message => "Here we go",
                                               });


    $res = from_json($mech->content);
    diag Dumper($res);
    ok !$res->{error};
    ok $res->{job};
    ok $res->{url};

    while (my $job = $site->jobs->dequeue) {
        $job->dispatch_job;
    }
    $mech->get_ok("/$type/api-test");
    $mech->get_ok("/$type/api-test.muse");
    $mech->content_is($body . "\n");
}
