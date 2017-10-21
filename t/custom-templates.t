#!perl

use strict;
use warnings;
use Test::More tests => 41;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Cwd;
use File::Spec::Functions qw/catdir catfile/;
use File::Copy::Recursive qw/dircopy/;
use File::Temp;
use AmuseWikiFarm::Schema;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site check_jobber_result start_jobber stop_jobber/;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $schema = AmuseWikiFarm::Schema->connect('amuse');

start_jobber($schema);

my $site = create_site($schema, "0ctmpl0");
$site->update({
               ttdir => 'custom-templates',
               epub => 1,
               tex => 1,
               html => 1,
              });

my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

$mech->get_ok('/');
$mech->get('/action/text/new');
is $mech->status, 401;
$mech->submit_form(with_fields => { __auth_user => 'root', __auth_pass => 'root' });
$mech->content_contains('You are logged in now!');

my $git_author = "Root <root@" . $site->canonical . ">";
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
    $mech->content_contains('Changes saved') or diag $mech->response->content;
    ok($mech->form_name('publish'));
    $mech->click;
    {
        my $res = check_jobber_result($mech);
        diag Dumper($res);
        my $base = $res->{produced_uri};
        my $bb_add = $base;
        $bb_add =~ s/library/bookbuilder\/add/;
        $mech->get_ok($bb_add);
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
        $mech->get_ok($base . '.epub');
        my $css = get_epub_css_from_url($mech);
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
    
# now let's try the bookbuilder
for my $use_ttdir (0..1) {
    $site->update({ ttdir => ($use_ttdir ? "custom-templates" : '') });
    foreach my $fmt (qw/pdf epub/) {
        $mech->get_ok('/bookbuilder');
        $mech->submit_form(with_fields => {
                                           title => 'x',
                                           format => $fmt,
                                          },
                           button => 'build');
        my $res = check_jobber_result($mech);
        diag Dumper($res);
        if ($fmt eq 'epub') {
            $mech->get_ok($res->{produced_uri});
            my $css = get_epub_css_from_url($mech);
            if ($use_ttdir) {
                like $css, qr{This is a custom template}, "Found CSS with custom string";
            }
            else {
                unlike $css, qr{This is a custom template}, "Found vanilla CSS";
            }
        }
        elsif ($fmt eq 'pdf') {
            $mech->get_ok($res->{sources});
            my $tex = get_tex_from_sources($mech);
            if ($use_ttdir) {
                like $tex, qr{\% this is a custom template}, "Found TeX with custom string";
            }
            else {
                unlike $tex, qr{\% this is a custom template}, "Found vanilla";
            }
        }
    }
}

stop_jobber();

sub get_epub_css_from_url {
    my $mech = shift;
    my $epub = $mech->content;
    open my $dh, "+<", \$epub;
    my $zipper = Archive::Zip->new;
    $zipper->readFromFileHandle($dh);
    my $css = $zipper->contents('OPS/stylesheet.css');
    return $css;
}
sub get_tex_from_sources {
    my $mech = shift;
    my $zip = $mech->content;
    open my $dh, "+<", \$zip;
    my $zipper = Archive::Zip->new;
    $zipper->readFromFileHandle($dh);
    my ($srctex) = $zipper->membersMatching(qr{/[0-9]+\.tex});
    my $tex = $zipper->contents($srctex->fileName);
    return $tex;
}
