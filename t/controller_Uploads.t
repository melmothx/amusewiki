use strict;
use warnings;
use utf8;
use Test::More tests => 16;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $pdf = catfile(qw/t files shot.pdf/);

ok (-f $pdf);
my $site_id = '0sf1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

my ($rev) = $site->create_new_text({ title => 'HELLO',
                                     lang => 'hr',
                                     textbody => '<p>ciao</p>',
                                   }, 'text');
$rev->add_attachment($pdf);
$rev->edit("#ATTACH h-o-hello-1.pdf\n" . $rev->muse_body);
my $expected = "h-o-hello-1.pdf";
is_deeply($rev->attached_pdfs, [ $expected ]);

$rev->commit_version;
$rev->publish_text;

my $thumb = catfile('thumbnails', $site_id, "$expected.thumb.png");

if (-f $thumb) {
    unlink $thumb or die $!;
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok("/uploads/$site_id/$expected");
$mech->get_ok("/uploads/$site_id/thumbnails/$expected.thumb.png");

ok (-f $thumb, "$thumb exists");
my $stat = (stat($thumb))[9];
sleep 2;
$mech->get_ok("/uploads/$site_id/thumbnails/$expected.thumb.png");
is ($stat, (stat($thumb))[9], "File has been cached correctly");

$mech->get_ok("/library/hello");
$mech->content_contains(qq{/uploads/$site_id/$expected"});
$mech->content_contains(qq{/uploads/$site_id/thumbnails/$expected.thumb.png"});

# touch the pdf
ok (-f $thumb, "$thumb exists");
$stat = (stat($thumb))[9];
sleep 2;
$mech->get_ok("/uploads/$site_id/thumbnails/$expected.thumb.png");
is ($stat, (stat($thumb))[9], "File has been cached correctly");

my $srcfile = $site->attachments->pdf_by_uri($expected)->f_full_path_name;;
ok(-f $srcfile, "Found $srcfile");
my $atime = my $mtime = time();
utime $atime, $mtime, $srcfile;
$mech->get_ok("/uploads/$site_id/thumbnails/$expected.thumb.png");

ok((stat($thumb))[9] > $stat, "Thumb $thumb regenerated");
