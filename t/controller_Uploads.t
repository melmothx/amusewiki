use strict;
use warnings;
use utf8;
use Test::More tests => 29;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;

my $pdf = catfile(qw/t files shot.pdf/);
my $png = catfile(qw/t files shot.png/);
ok (-f $pdf);
ok (-f $png);
my $site_id = '0sf1';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);

my ($rev) = $site->create_new_text({ title => 'HELLO',
                                     lang => 'hr',
                                     textbody => '<p>ciao</p>',
                                   }, 'text');
my $expected = $rev->add_attachment($pdf)->{attachment};
$rev->edit("#ATTACH $expected\n" . $rev->muse_body);
is $expected, "h-o-hello-1.pdf", "$expected is h-o-hello-1.pdf";
is_deeply($rev->attached_pdfs, [ $expected ]);
my $png_att = $rev->add_attachment($png)->{attachment};
is ($png_att, "h-o-hello-1.png");

$rev->commit_version;
$rev->publish_text;

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok("/uploads/$site_id/$expected");
$mech->get_ok("/library/hello");
$mech->content_contains(qq{/uploads/$site_id/$expected"});
$mech->content_contains(qq{/uploads/$site_id/thumbnails/$expected.thumb.png"});


foreach my $file ($expected, $png_att) {
    my $thumb = catfile('thumbnails', $site_id, "$file.thumb.png");
    diag "Checking $thumb\n";
    if (-f $thumb) {
        unlink $thumb or die $!;
    }
    $mech->get_ok("/uploads/$site_id/thumbnails/$file.thumb.png");

    ok (-f $thumb, "$thumb exists");
    my $stat = (stat($thumb))[9];
    sleep 2;
    $mech->get_ok("/uploads/$site_id/thumbnails/$file.thumb.png");
    is ($stat, (stat($thumb))[9], "File has been cached correctly");


    # touch the pdf
    ok (-f $thumb, "$thumb exists");
    $stat = (stat($thumb))[9];
    sleep 2;
    $mech->get_ok("/uploads/$site_id/thumbnails/$file.thumb.png");
    is ($stat, (stat($thumb))[9], "File has been cached correctly");

    my $srcfile = $site->attachments->by_uri($file)->f_full_path_name;;
    ok(-f $srcfile, "Found $srcfile");
    my $atime = my $mtime = time();
    utime $atime, $mtime, $srcfile;
    $mech->get_ok("/uploads/$site_id/thumbnails/$file.thumb.png");

    ok((stat($thumb))[9] > $stat, "Thumb $thumb regenerated");
}




