use strict;
use warnings;
use utf8;
use Test::More tests => 35;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output,    ":encoding(utf8)";


unless (eval q{use Test::WWW::Mechanize::Catalyst 0.55; 1}) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst >= 0.55 required';
    exit 0;
}

use Test::WWW::Mechanize::Catalyst;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use File::Copy qw/copy/;
use Text::Amuse::Compile::Utils qw/write_file read_file append_file/;
use Data::Dumper;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;

my $site_id = '0beamer0';
my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site = create_site($schema, $site_id);
ok !$site->sl_tex, "No sl.tex";
$site->update({ sl_pdf => 1,
                cgit_integration => 1,
                secure_site => 0,
                sansfont => 'Iwona',
                monofont => 'DejaVu Sans Mono',
                beamertheme => 'Madrid',
                beamercolortheme => 'wolverine',
              });
ok $site->sl_tex;

my $mech = Test::WWW::Mechanize::Catalyst
  ->new(catalyst_app => 'AmuseWikiFarm',
        host => $site->id . '.amusewiki.org');

use File::Path qw/make_path/;
my $destination = catdir($site->repo_root, qw/s ss/);
make_path($destination, { verbose => 1 }) unless -d $destination;
foreach my $muse ('slides.muse', 'slides-s-no.muse') {
    copy(catfile(qw/t files/, $muse), $destination)
      or die "Cannot t/files/$muse into $destination $!";
}
$site->git->add($destination);
$site->git->commit({ message => "Added files" });
$site->update_db_from_tree;
ok (-f catfile($destination, 'slides.sl.tex'), "Slides sources created");
ok (-f catfile($destination, 'slides.sl.pdf'), "Slides created");
ok (! -f catfile($destination, 'slides-s-no.sl.pdf'),
    "Slides not created if #slides no");
my $tex_body = read_file(catfile($destination, 'slides.sl.tex'));
like($tex_body, qr{Iwona}, "Found the sans font");
like($tex_body, qr{wolverine}, "Found the beamer color theme");
like($tex_body, qr{Madrid}, "Found the beamer theme");
like($tex_body, qr{DejaVu Sans Mono}, "Found the font");
$mech->get_ok('/library/slides');
$mech->content_contains('Slides (PDF)');
$mech->get_ok('/library/slides-s-no');
$mech->content_lacks('Slides (PDF)');
$mech->get_ok('/library/slides.sl.pdf');
$mech->get_ok('/library/slides.sl.tex');
$mech->get('/library/slides-s-no.sl.pdf');
is ($mech->status, '404', "slides for slides-s-no not found");
$mech->get('/library/slides-s-no.sl.tex');
is ($mech->status, '404', "slides for slides-s-no not found");

$mech->get_ok('/login');
$mech->submit_form(form_id => 'login-form',
                   fields => { username => 'root',
                               password => 'root',
                             },
                   button => 'submit');
$mech->get_ok('/action/text/new');
$mech->content_contains('Produce slides');
$mech->get_ok("/admin/sites/edit/$site_id");
$mech->form_id("site-edit-form");
$mech->untick(sl_pdf => 'on');
$mech->click("edit_site");
$mech->content_lacks(q{id="error_message"}) or die $mech->content;
ok(!$site->discard_changes->sl_pdf, "sl_pdf disabled");
$mech->get_ok('/action/text/new');
$mech->content_lacks('Produce slides');

ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->set_fields(author => 'pippo',
                  title => "No slides",
                  textbody => "\n");
$mech->click;
$mech->content_contains('Created new text');
$mech->content_lacks('#slides');

$mech->get_ok("/admin/sites/edit/$site_id");
$mech->form_id("site-edit-form");
$mech->tick(sl_pdf => 'on');
$mech->click;
ok($site->discard_changes->sl_pdf, "Slides are active now");
$mech->get_ok('/action/text/new');
$mech->content_contains('Produce slides');
ok($mech->form_id('ckform'), "Found the form for uploading stuff");
$mech->tick(slides => 'yes');
$mech->set_fields(author => 'pippo',
                  title => "Slides! for pippo",
                  textbody => "\n");
$mech->click;
$mech->content_contains('Created new text');
$mech->content_contains("#slides yes\n");



