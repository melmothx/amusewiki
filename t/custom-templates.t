#!perl

use strict;
use warnings;
use Test::More tests => 27;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Cwd;
use File::Spec::Functions qw/catdir catfile/;
use File::Copy::Recursive qw/dircopy/;
use File::Temp;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site check_jobber_result/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $init = catfile(getcwd(), qw/script jobber.pl/);
system($init, 'restart');


my $schema = AmuseWikiFarm::Schema->connect('amuse');

my $site = create_site($schema, "0ctmpl0");
$site->update({
               ttdir => 'custom-templates',
               epub => 1,
               tex => 1,
               html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);


$mech->get_ok('/action/text/new');

ok($mech->form_id('login-form'), "Found the login-form");

$mech->set_fields(username => 'root',
                  password => 'root');
my $git_author = "Root <root@" . $site->canonical . ">";
$mech->click;

$mech->content_contains('You are logged in now!');

for my $use_ttdir (0..1) {
    $mech->get_ok('/action/text/new');
    diag "Uploading a text";
    ok($mech->form_id('ckform'), "Found the form for uploading stuff");
    $mech->set_fields(author => 'pippo',
                      title => "My text $use_ttdir",
                      textbody => "Hello <em>there</em>\n");
    $mech->click;
    $mech->content_contains('Created new text');
    $mech->form_id('museform');
    $mech->click('commit');
    $mech->content_contains('Changes committed') or diag $mech->response->content;
    ok($mech->form_name('publish'));
    $mech->click;
    {
        my $res = check_jobber_result($mech);
        diag Dumper($res);
        my $base = $res->{produced_uri};
        $mech->get_ok($base);
        foreach my $ext ('.tex', '.html') {
            $mech->get_ok($base . $ext);
            if ($use_ttdir) {
                $mech->content_contains('this is a custom template');
            }
            else {
                $mech->content_lacks('this is a custom template');
            }
        }
        my $zipper = Archive::Zip->new;
        $mech->get_ok($base . '.epub');
        my $epub = $mech->content;
        open my $dh, "+<", \$epub;
        $zipper->readFromFileHandle($dh);
        my $css = $zipper->contents('OPS/stylesheet.css');
        if ($use_ttdir) {
            like $css, qr{This is a custom template};
        }
        else {
            unlike $css, qr{This is a custom template};
        }
    }
    unless ($use_ttdir) {
        dircopy(catdir(qw/t custom-templates/), catdir($site->repo_root, $site->ttdir))
          or die "Cannot copy t/custom-templates into repo " . $site->ttdir;
    }
}
    
    


system($init, 'stop');

