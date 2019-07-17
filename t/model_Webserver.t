use strict;
use warnings;

BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 11;
use Test::WWW::Mechanize::Catalyst;
use File::Spec;
use File::Copy qw/move/;
use Data::Dumper;
use Path::Tiny;
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
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->get('/action/text/new?__language=hr');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => 'title',
                  textbody => "\n");

$mech->click;
diag $mech->uri;
diag "Changing language user interface";
$mech->get($mech->uri . '?__language=en');

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

{
    my $ws = AmuseWikiFarm::Utils::Webserver->new;
    my $directions = $ws->generate_nginx_config($site);
    diag $directions;
    if ($directions =~ m!diff -Nu /etc/nginx/sites-enabled/amusewiki\s+(.+?)\s*$!m) {
        my $file = path($1);
        ok $file->exists;
        diag $file;
        my $content = $file->slurp_utf8;
        like $content, qr{client_max_body_size 8m};
    }
}

$schema->resultset('User')->update({ preferred_language => undef });
