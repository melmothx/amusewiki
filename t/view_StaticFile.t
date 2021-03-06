use strict;
use warnings;
use utf8;
use Test::More tests => 498;
BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
    $ENV{CATALYST_DEBUG} = 0;
    use_ok 'AmuseWikiFarm::View::StaticFile';
}

use Data::Dumper::Concise;
use Cwd;
use Test::WWW::Mechanize::Catalyst;

# attachments are accessible everywhere
my %files = (
             '/special/i-x-myfile.png' => 'image/png',
             '/special/a-t-myfile.pdf' => 'application/pdf',
             '/library/i-x-myfile.png' => 'image/png',
             '/library/a-t-myfile.pdf' => 'application/pdf',
             '/a-t-myfile.pdf' => 'application/pdf',
             '/i-x-myfile.png' => 'image/png',
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

$mech->get_ok('/');
is ($mech->response->header('Cache-Control'), 'no-cache', "/ has no-cache") or die;

$mech->get_ok('/category/topic/i-x-myfile.png');
$mech->get_ok('/category/topic/a-t-myfile.pdf');


foreach my $get (sort keys %files) {
    $mech->get_ok($get);
    my $type = $mech->response->content_type;
    if ($type eq 'text/plain') {
        is $mech->response->content_type_charset, 'UTF-8', "encoding correct";
    }
    is $type, $files{$get}, "$get has type $files{$get}";
    ok ($mech->response->header('ETag'), "Etag not present");
    ok ($mech->response->header('Last-Modified'),
        "Last-Modified present: " . $mech->response->header('Last-Modified'));
    is ($mech->response->header('Cache-Control'), 'no-cache', "$get has no-cache") or die;
}

foreach my $get ('/feed', '/library') {
    $mech->get_ok($get);
    ok ($mech->response->header('ETag'), "Etag is present: " . $mech->response->header('ETag')) or
      diag Dumper($mech->response->headers);
    ok (!$mech->response->header('Last-Modified'), "Last-Modified not present in $get") or
      diag Dumper($mech->response->headers);
}


foreach my $get ('/special/index', '/library/first-test') {
    $mech->get_ok($get);
    ok ($mech->response->header('ETag'), "Etag is present: " . $mech->response->header('ETag')) or
      diag Dumper($mech->response->headers);
    ok ($mech->response->header('Last-Modified'), "Last-Modified present in $get") or
      diag Dumper($mech->response->headers);
}


# emulate X-SendFile
foreach my $h (qw/X-Sendfile X-Lighttpd-Send-File X-Accel-Redirect/) {
    if ($h eq 'X-Accel-Redirect') {
        $mech->add_header('X-Accel-Mapping' => getcwd() . '=' . '/private');
    }
    my %etags;
    $mech->add_header('X-Sendfile-Type' => $h);
    foreach my $get (sort keys %files) {
        $mech->get_ok($get);
        my $type = $mech->response->content_type;
        ok($mech->response->header($h), "Found $h header in $get!: " . $mech->response->header($h));
        is $type, $files{$get}, "Content-type is correct ($files{$get})";
        my $etag = $mech->response->header('ETag');
        ok ($etag, "Etag present");
        if ($get =~ qr{/(special|library)/(i-x-myfile\.png|a-t-myfile\.pdf)}) {
            is ($etags{$etag}, '/' . $2, "Same file, same etag") or diag Dumper(\%etags, [ sort keys %files ]);
        } else {
            ok (!$etags{$etag}, "Etag $etag was not yet used yet ($get)")
              or diag "Etag is the same as $etags{$etag}" . Dumper(\%etags, [ sort keys %files ]);
            $etags{$etag} = $get;
        }
        ok ($mech->response->header('Last-Modified'),
            "Last-Modified present: " . $mech->response->header('Last-Modified'));
        ok ($mech->response->content eq '', "Empty body for $get");
    }
}

$mech->delete_header('X-Accel-Mapping');
$mech->delete_header('X-Sendfile-Type');

$mech->get_ok('/');
my $icon = "/sitefiles/0blog0/favicon.ico";
$mech->content_contains($icon);
$mech->get_ok($icon);
is $mech->response->header('content-type'), 'image/x-icon';
$mech->get_ok('/favicon.ico');
is $mech->response->header('content-type'), 'image/x-icon';

$mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                            host => "test.amusewiki.org");

$mech->get_ok('/');

$mech->content_lacks('favicon.ico');
$mech->get($icon);

is $mech->status, '404', "404, no leaking between sites";

$mech->get('/aasdlfj/asdkf.png');
is $mech->status, 404;
is $mech->response->header('Cache-Control'), 'no-cache, no-store, must-revalidate';
