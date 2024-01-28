#!perl

use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
use Test::More;
use Path::Tiny;
use Data::Dumper::Concise;

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

my $schema = AmuseWikiFarm::Schema->connect('amuse');
# use the 0blog0 here.

my $site = $schema->resultset('Site')->find('0blog0');
my $user = $schema->resultset('User')->find({ username => 'root' });
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);
my $now = DateTime->now(time_zone => 'UTC');
$site->bookcovers->delete;
my $anon_bc = $site->bookcovers->create({
                                         created => $now,
                                        })->discard_changes;
ok $anon_bc;

my $user_bc = $site->bookcovers->create({
                                         user => $user,
                                         created => $now,
                                        })->discard_changes;
ok $user_bc;

{
    my $wd = $anon_bc->create_working_dir;
    ok $wd->exists;
    diag "Working dir is $wd";
    my $tokens =  $anon_bc->parse_template;
    is_deeply $tokens, {
                        title_muse =>  { name => 'title',  type => 'muse' },
                        author_muse => { name => 'author', type => 'muse' },
                        back_text_muse => { name => 'back_text', type => 'muse' },
                       };
    $anon_bc->populate_tokens;
    $anon_bc->populate_tokens;
    is $anon_bc->bookcover_tokens->count, 3;
    $anon_bc->update_from_params({
                                  title_muse => "Title *title*",
                                  author_muse => "Author *author*",
                                  spinewidth => 'asdf',
                                  back_text_muse => "This\n\nIs\n\nThe *back*",
                                 });
    ok $anon_bc->font_name, "Font name set";
    diag $anon_bc->font_name;
    is $anon_bc->spinewidth, 0;
    $anon_bc->update_from_params({
                                  spinewidth => 15,
                                  font_name => 'TeX Gyre Pagella',
                                 });
    is $anon_bc->font_name, 'TeX Gyre Pagella';
    $anon_bc->update_from_params({
                                  spinewidth => 15,
                                  font_name => 'Random crap',
                                 });
    is $anon_bc->font_name, ($anon_bc->all_fonts)[0]->name;
    is $anon_bc->spinewidth, 15;

    $anon_bc->update_from_params({
                                  spinewidth => 15,
                                  font_name => 'TeX Gyre Pagella',
                                  language_code => 'fr',
                                 });
    my $outfile = $anon_bc->write_tex_file;
    ok $outfile->exists;
    my $tex_body = $outfile->slurp_utf8;
    like $tex_body, qr{The \\emph\{back\}};
    like $tex_body, qr(\\usepackage.*french.*\{babel\});
    like $tex_body, qr{texgyrepagella};
    diag $tex_body;
    my $res = $anon_bc->produce_pdf(sub { diag @_ });
    ok $res->{success} or die $res->{stdout};
    # diag Dumper($res);
    ok $anon_bc->zip_path;
    ok $anon_bc->pdf_path;
    ok -f $anon_bc->pdf_path, $anon_bc->pdf_path . " exists";
    ok -f $anon_bc->zip_path, $anon_bc->zip_path . " exists";
}

done_testing;
