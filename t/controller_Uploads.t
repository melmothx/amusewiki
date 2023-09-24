use strict;
use warnings;
use utf8;
use Test::More tests => 63;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Path::Tiny;
use Data::Dumper::Concise;

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
$rev->edit("#cover $png_att\n" . $rev->muse_body);
is ($png_att, "h-o-hello-2.png");

$rev->commit_version;
$rev->publish_text;

foreach my $att ($site->attachments) {
    $att->generate_thumbnails;
    foreach my $method (qw/thumb small large/) {
        is $att->thumbnails->$method->count, 1;
        foreach my $thumb ($att->thumbnails->$method) {
            my $file = $thumb->path_object;
            ok ($file->exists, "$file created");
        }
    }
}

my $text = $rev->title->discard_changes;
is ($text->cover_uri, '/library/h-o-hello-2.png');
is ($text->cover_thumbnail_uri, '/uploads/0sf1/thumbnails/h-o-hello-2.png.thumb.png');
is ($text->cover_small_uri, '/uploads/0sf1/thumbnails/h-o-hello-2.png.small.png');


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "$site_id.amusewiki.org");

$mech->get_ok("/uploads/$site_id/$expected");
$mech->get_ok($text->cover_thumbnail_uri);
$mech->get_ok($text->cover_uri);
$mech->get_ok($text->cover_small_uri);
$mech->get_ok("/library/hello");
$mech->content_contains(qq{/uploads/$site_id/$expected"});
$mech->content_contains(qq{/uploads/$site_id/thumbnails/$expected.large.png"});


foreach my $attachment ($site->attachments) {
    is $attachment->thumbnails->count, 3;
    my $file_path = $attachment->f_full_path_name;
    my $file = $attachment->uri;
    foreach my $type (qw/small thumb large/) {
        my $thumb = catfile('thumbnails', $site_id, "$file.$type.png");
        diag "Checking $thumb\n";
        if (-f $thumb) {
            unlink $thumb or die $!;
        }
        ok (! -f $thumb, "$thumb does not exist");
        $mech->get("/uploads/$site_id/thumbnails/$file.$type.png");
        is $mech->status, 404;
    }
    $site->index_file($file_path);
    foreach my $type (qw/small thumb large/) {
        my $thumb = catfile('thumbnails', $site_id, "$file.$type.png");
        ok (-f $thumb, "$thumb exists");
        $mech->get_ok("/uploads/$site_id/thumbnails/$file.$type.png");
    }
}
ok $site->thumbnails->min_dimensions(200, 200)->count, "Found thumbs with dimensions > 200";
$mech->get_ok('/latest');
$mech->content_contains("/uploads/$site_id/thumbnails/$png_att.small.png");

{
    my $bad = Path::Tiny->tempfile;
    $bad->spew_raw("%PDF-1.3\nalsdfjlaksdjflkasdflkjasdf\n");
    my ($rev) = $site->create_new_text({ title => 'In error',
                                         lang => 'hr',
                                         textbody => '<p>ciao</p>',
                                       }, 'text');
    my $add  = $rev->add_attachment("$bad");
    diag Dumper($add);
    my $first = $add->{attachment};
    diag "Added $first";
    $rev->edit("#ATTACH $first\n" . $rev->muse_body);
    my $second = $rev->add_attachment("$bad")->{attachment};
    diag "Added $second";
    $rev->commit_version;
    $rev->publish_text;
    foreach my $att ($site->attachments) {
        $att->generate_thumbnails;
    }
    is $site->attachments->search({ errors => { '<>' => '' } })->count, 2;
    $mech->get_ok('/login');
    ok $mech->submit_form(with_fields => {__auth_user => 'root', __auth_pass => 'root' });
    $mech->get_ok('/attachments/orphans');
    $mech->content_contains('attachment-error');
    $mech->get_ok('/attachments/list');
    $mech->content_contains('attachment-error');
}
