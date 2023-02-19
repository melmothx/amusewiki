#!perl

use utf8;
use strict;
use warnings;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Test::More tests => 10;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Path::Tiny;
use YAML qw/DumpFile/;
use Test::WWW::Mechanize::Catalyst;

my $schema = AmuseWikiFarm::Schema->connect('amuse');


my $site_id = "0flth0";
my $site = create_site($schema, $site_id);

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


path($site->path_for_uploads, 'pizza.pdf')->spew_raw(<<'DUMMY');
%PDF-1.5
%
4 0 obj
<</Filter/FlateDecode/Length 39>>
stream
DUMMY
path(t => files => 'shot.pdf')->copy($site->path_for_uploads);

my $muse_file = path($site->repo_root, t => tt => 'test.muse');
$muse_file->parent->mkpath;
$muse_file->spew_utf8("#ATTACH pizza.pdf shot.pdf\n#title pizza\nlang en\n\npizza");
$site->update_db_from_tree(sub { diag join(' ', @_) });
$mech->get_ok('/library/test');
$mech->content_contains('failed-thumbnail-generation-preamble');
$mech->content_contains('failed-thumbnail-generation-attachment');
$mech->get_ok('/uploads/0flth0/pizza.pdf');
$mech->get_ok('/uploads/0flth0/shot.pdf');
$mech->get_ok('/login');
ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' }) or die;
$mech->get_ok('/attachments/list');
$mech->content_like(qr{<img\s+
                       class="[^"]*?
                       attachment-with-thumb
                       [^>]*
                       src="[^"]*?shot\.pdf\.small\.png
                  }x);
$mech->content_like(qr{<i\s+
                       title="pizza\.pdf
                       [^>]*
                       attachment-without-thumb}x);
