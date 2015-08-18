use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 6;
use Test::WWW::Mechanize::Catalyst;
use File::Spec;
use File::Copy qw/move/;
use Data::Dumper;

use_ok 'AmuseWikiFarm::Model::AMWConfig';

my $existing = File::Spec->catdir(qw/root static js ckeditor/);
my $backup = File::Spec->catdir(qw/root static js ckeditor-old/);

my $ckeditor_is_local = -d $existing;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => 'blog.amusewiki.org');

$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');


foreach my $path ('/utils/import', '/action/text/new') {
    $mech->get_ok($path);
    if ($ckeditor_is_local) {
        $mech->content_contains('blog.amusewiki.org/static/js/ckeditor/ckeditor.js', "local js found in $path");
    }
    else {
        $mech->content_contains('cdn.ckeditor.com/4.4.3/standard/ckeditor.js', "cdn js found in $path");
    }
}

