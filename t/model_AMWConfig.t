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

use_ok 'AmuseWikiFarm::Model::AMWConfig';

my $existing = File::Spec->catdir(qw/root static js ckeditor/);
my $backup = File::Spec->catdir(qw/root static js ckeditor-old/);

my $ckeditor_is_local = -d $existing;

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
    if ($ckeditor_is_local) {
        $mech->content_contains($site->canonical . '/static/js/ckeditor/ckeditor.js', "local js found in $path");
    }
    else {
        $mech->content_contains('cdn.ckeditor.com/4.4.3/standard/ckeditor.js', "cdn js found in $path");
    }
}

$mech->get('/action/text/new');
$mech->content_contains("localization/messages_hr.js");
diag "Changing language user interface";
$mech->get('/set-language?lang=en&goto=action/text/new');
$mech->content_lacks("localization/messages_en.js");
$mech->content_lacks("localization/messages_hr.js");
$mech->content_lacks("localization/messages");
$mech->content_contains("jquery.validate.min.js") or diag $mech->content;
