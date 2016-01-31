use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 11;
use Test::WWW::Mechanize::Catalyst;
use File::Spec;
use File::Copy qw/move/;
use Data::Dumper;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;

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


foreach my $path ('/utils/import', '/action/text/new') {
    $mech->get_ok($path);
    # the default configuration is to have them static. You turn the
    # cdn with a local config. Deprecated.  So...
    $mech->content_contains($site->canonical . '/static/js/ckeditor/ckeditor.js',
                            "local js found in $path");
}

$mech->get('/action/text/new');
$mech->content_contains("localization/messages_hr.js");
diag "Changing language user interface";
$mech->get('/set-language?lang=en&goto=action/text/new');
$mech->content_lacks("localization/messages_en.js");
$mech->content_lacks("localization/messages_hr.js");
$mech->content_lacks("localization/messages");
$mech->content_contains("jquery.validate.min.js") or diag $mech->content;
