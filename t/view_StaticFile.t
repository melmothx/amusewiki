use strict;
use warnings;
use utf8;
use Test::More tests => 74;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{CATALYST_DEBUG} = 0;
    use_ok 'AmuseWikiFarm::View::StaticFile';
}

use Data::Dumper;
use Test::WWW::Mechanize::Catalyst;

# attachments are accessible everywhere
my %files = (
             '/special/i-x-myfile.png' => 'image/png',
             '/special/a-t-myfile.pdf' => 'application/pdf',
             '/library/i-x-myfile.png' => 'image/png',
             '/library/a-t-myfile.pdf' => 'application/pdf',

            );

my %exts = (
            muse => 'text/plain',
            zip => 'application/zip',
            pdf => 'application/pdf',
            tex => 'application/x-tex',
            epub => 'application/epub+zip',
            html => 'text/html',
           );

foreach my $f ('/special/index',
               '/library/first-test') {
    foreach my $ext (keys %exts) {
        my $get = $f . '.' . $ext;
        $files{$get} = $exts{$ext};
    }
}

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => "blog.amusewiki.org");

foreach my $get (sort keys %files) {
    $mech->get_ok($get);
    my $type = $mech->response->content_type;
    is $type, $files{$get}, "$get has type $files{$get}";
    ok (!$mech->response->header('ETag'), "Etag not present");
    ok ($mech->response->header('Last-Modified'),
        "Last-Modified present: " . $mech->response->header('Last-Modified'));
}

foreach my $get ('/special/index', '/feed', '/library/first-test') {
    $mech->get_ok($get);
    ok ($mech->response->header('ETag'), "Etag is present: " . $mech->response->header('ETag')) or
      diag Dumper($mech->response->headers);
    ok (!$mech->response->header('Last-Modified'), "Last-Modified not present") or
      diag Dumper($mech->response->headers);
}


