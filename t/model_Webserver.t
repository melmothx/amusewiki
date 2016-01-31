use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 13;
use Test::WWW::Mechanize::Catalyst;
use File::Spec;
use File::Copy qw/move/;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use AmuseWikiFarm::Utils::Webserver;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0val0');

$site->update({ multilanguage => 'hr en es',
                locale => 'hr',
              });

use_ok 'AmuseWikiFarm::Model::Webserver';

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');


$mech->get('/action/text/new');
$mech->content_contains("localization/messages_hr.js");
diag "Changing language user interface";
$mech->get('/set-language?lang=en&goto=action/text/new');
$mech->content_lacks("localization/messages_en.js");
$mech->content_lacks("localization/messages_hr.js");
$mech->content_lacks("localization/messages");
$mech->content_contains("jquery.validate.min.js") or diag $mech->content;

{
    my $ws = AmuseWikiFarm::Utils::Webserver->new;

  SKIP: {
        skip "ckeditor use cdn", 2 if $ws->ckeditor_use_cdn;
        ok $ws->ckeditor_location, "Found ck location";
        ok (-d $ws->ckeditor_location, $ws->ckeditor_location . " exists");
    }
  SKIP: {
        skip "highlight use cdn", 2 if $ws->highlight_use_cdn;
        ok $ws->highlight_location, "Found hightlight location";
        ok (-d $ws->highlight_location, $ws->highlight_location . " exists");
    }
}

{
    my $ws = AmuseWikiFarm::Utils::Webserver->new(highlight_location => '/bla',
                                                  ckeditor_location => '/asdlfj');
    ok $ws->ckeditor_use_cdn;
    ok $ws->highlight_use_cdn;
}
