#!perl

use strict;
use warnings;
use utf8;
use File::Spec::Functions qw/catfile catdir/;
use Test::More tests => 260;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use Path::Tiny;
use AmuseWikiFarm::Utils::Amuse qw/split_pdf/;

my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, '0gall0');
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
$site->update({ pdf => 1 });

my $tmpdir = Path::Tiny->tempdir;
{
    my $file = path(qw/t files manual.pdf/);
    my @pdfs = split_pdf("$file", "$tmpdir");
    ok scalar(@pdfs), "PDF created";
    foreach my $pdf (@pdfs) {
        ok $pdf->exists, "$pdf exists";
    }
    my ($rev) = $site->create_new_text({ title => 'HELLO',
                                         textbody => '<p>ciao</p>',
                                         uri => 'hello',
                                       }, 'text');
    $rev->edit($rev->muse_body);
    $rev->add_attachment("$file");
    diag $rev->muse_body;
    $rev->append_to_revision_body("\n\n[[my-file.png]\n");
    like $rev->muse_body, qr/title HELLO.*ciao.*my-file\.png/s;
    diag $rev->muse_body;
    my $out = $rev->embed_attachment($file);
    ok ($out->{attachment}) and diag Dumper($out);
    $out = $rev->embed_attachment(path(qw/t files shot.png/));
    ok ($out->{attachment}) and diag Dumper($out);
    my $body = $rev->muse_body;
    foreach my $i (1..64) {
        like $body, qr/\[\[h-o-hello-\Q$i\E\.png f\]\]/, "Found png $i";
    }
    $rev->commit_version;
    $rev->publish_text;
}

$mech->get_ok('/library/hello') or die;
my $html = $mech->content;
foreach my $i (1..64) {
    my $uri = 'h-o-hello-' . $i . '.png';
    like $html, qr/src="\Q$uri\E"/, "Found $uri image in the body";
    $mech->get_ok('/library/' . $uri);
}
