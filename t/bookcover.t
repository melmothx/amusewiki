#!perl

BEGIN {
    $ENV{DBIX_CONFIG_DIR} = "t";
};

use utf8;
use strict;
use warnings;
use AmuseWikiFarm::Schema;
use File::Spec::Functions qw/catfile catdir/;
use lib catdir(qw/t lib/);
use AmuseWiki::Tests qw/create_site/;
use Test::WWW::Mechanize::Catalyst;
use DateTime;
use Test::More tests => 107;
use Path::Tiny;
use Data::Dumper::Concise;
use IPC::Run (qw/run/);

my $schema = AmuseWikiFarm::Schema->connect('amuse');
# use the 0blog0 here.

my $site_id = '0bookcovers0';
my $site = create_site($schema, $site_id);
my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                               host => $site->canonical);

{
    my %expect;
    my $td = path($site->repo_root)->child('templates')->child('bookcovers');
    foreach my $tn (qw/first second/) {
        my $target = $td->child($tn);
        $target->mkpath;
        my $ttbody = <<'TTBODY';
% document class populated by us
\begin{document}
\begin{bookcover}
\bookcovercomponent{center}{front}%
{{\bfseries\Huge [% title_muse_str %]\par\includegraphics[width=0.6\partwidth]{images/sample.png}}}
\end{bookcover}
\end{document}
TTBODY
        $ttbody .= "% $tn\n";
        $target->child('cover.tt')->spew_utf8($ttbody);
        $target->child('images')->mkpath;
        path("t/files/shot.png")->copy($target->child('images')->child("sample.png"));
        $expect{$tn} = "$target";
    }
    $site->update({ ttdir => 'templates' });
    is_deeply $site->valid_bookcover_templates, \%expect or die;
}


my $user = $schema->resultset('User')->find({ username => 'root' });
my $now = DateTime->now(time_zone => 'UTC');
$site->bookcovers->delete;
my $anon_bc = $site->bookcovers->create({
                                         created => $now,
                                        })->discard_changes;
ok $anon_bc;

{
    my $wd = $anon_bc->create_working_dir;
    ok $wd->exists;
    diag "Working dir is $wd";
    my $tokens =  $anon_bc->parse_template;
    is_deeply $tokens, [
                        { name => 'author', type => 'muse_str', full_name => 'author_muse_str' },
                        { name => 'title',  type => 'muse_str', full_name => 'title_muse_str' },
                        { name => 'subtitle',  type => 'muse_str', full_name => 'subtitle_muse_str' },
                        { name => 'image', type => 'file', full_name => 'image_file' },
                        { name => 'image_width_in_mm', type => 'int', full_name => 'image_width_in_mm_int' },
                        { name => "front_footer", type => "muse_str", full_name => "front_footer_muse_str" },
                        { name => 'back_text', type => 'muse_body', full_name => 'back_text_muse_body' },
                        { name => 'isbn', type => 'isbn', full_name => 'isbn_isbn' }
                       ] or die Dumper($tokens);
    path("t/files/shot.png")->copy($anon_bc->working_dir->child("f1.png"));
    $anon_bc->populate_tokens;
    $anon_bc->populate_tokens;
    is $anon_bc->bookcover_tokens->count, 8;
    $anon_bc->update_from_params({
                                  title_muse_str => "Title *title*",
                                  author_muse_str => "Author *author*",
                                  spinewidth => 'asdf',
                                  back_text_muse_body => "This\n\nIs\n\nThe *back*",
                                  image_file => "f1.png",
                                  image_width_in_mm_int => 10,
                                  front_footer_muse_str  => "Test",
                                  subtitle_muse_str => "test",
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
                                  language_code => 'it',
                                 });
    my $outfile = $anon_bc->write_tex_file;
    ok $outfile->exists;
    my $tex_body = $outfile->slurp_utf8;
    like $tex_body, qr{The \\emph\{back\}};
    like $tex_body, qr(\\usepackage.*italian.*\{babel\});
    like $tex_body, qr{texgyrepagella};
    like $tex_body, qr{includegraphics};
    diag "$outfile";
    my $res = $anon_bc->produce_pdf(sub { diag @_ });
    ok $res->{success} or die $res->{stdout};
    # diag Dumper($res);
    ok $anon_bc->zip_path;
    ok $anon_bc->pdf_path;
    ok -f $anon_bc->pdf_path, $anon_bc->pdf_path . " exists";
    ok -f $anon_bc->zip_path, $anon_bc->zip_path . " exists";
    my $token = $anon_bc->bookcover_tokens->create({ token_name => 'test' });
    my @checks = (
                  [ float => '0.81', '0.81' ],
                  [ float => '0.1', '0.1' ],
                  [ float => '0.0', '0.0' ],
                  [ float => 'pippo', '0' ],
                  [ float => '1', '1'],
                  [ int => '0.01', '0' ],
                  [ int => 'pippo', '0' ],
                  [ int => '3', '3'],
                  [ int => '33', '33'],
                  [ muse => "asdfa", ''], # invalid type
                  [ muse_str => "asdfa\n*em*", 'asdfa \emph{em}'],
                  [ muse_str => "asdfa<br>*em*", 'asdfa \emph{em}'],
                  [ muse_body => "asdfa\n\n*em*", "asdfa\n\n\n\\emph{em}"],
                  [ file => "f1.pdf", "f1.pdf" ],
                  [ file => "f 2.pdf", "" ],
                  [ file => "f2.png", "f2.png" ],
                  [ file => "f2.jpg", "f2.jpg" ],
                  [ file => "f2.jpeg", "f2.jpeg" ],
                  [ file => " f2.jpg ", "" ],
                  [ file => " f2.jpeg ", "" ],
                  [ file => " c1.jpeg ", "" ],
                  [ file => " .pdf ", "" ],
                 );
    foreach my $c (@checks) {
        $token = $token->get_from_storage;
        $token->update({
                        token_name => "pizza_" . $c->[0],
                        token_value => $c->[1],
                       });
        is $token->token_value_for_template, $c->[2], join(' => ', @$c);
    }
}

my $user_bc = $site->bookcovers->create_and_initalize({
                                                       user => $user,
                                                       created => $now,
                                                       template => 'first',
                                                      });
ok $user_bc;

{
    my $outfile = $user_bc->write_tex_file;
    ok $outfile->exists;
    diag "TeX file is $outfile";
    my $tex_body = $outfile->slurp_utf8;
    diag $tex_body;
    like $tex_body, qr{images/sample.png};
    my $res = $user_bc->produce_pdf(sub { diag @_ });
    ok $res->{success};
    ok $user_bc->zip_path;
    ok $user_bc->pdf_path;
    ok -f $user_bc->pdf_path, $user_bc->pdf_path . " exists";
    ok -f $user_bc->zip_path, $user_bc->zip_path . " exists";
}

# anonymous
{
    $mech->get('/bookcovers');
    ok $mech->submit_form(with_fields => { __auth_human => 16 });
    ok $mech->submit_form(with_fields => { template => "" });
    my $current_uri = $mech->uri->path;
    $mech->get_ok('/bookcovers?bare=1');
    my $body = $mech->content;
    my @found;
    while ($body =~ m{(/bookcovers/bc/(\d+)/edit)}g) {
        diag $1;
        push @found, $2;
    }
    is scalar(@found), 1, "Found only one cover";
}


my $tuser = $site->update_or_create_user({
                                         username => 'bclib',
                                         password => 'pallino'
                                        });
# librarian
{
    $mech->get_ok('/login');
    $tuser->set_roles([{ role => 'librarian' }]);
    $mech->submit_form(with_fields => { __auth_user => 'bclib', __auth_pass => 'pallino' });
    $mech->get_ok('/bookcovers');
    ok $mech->submit_form(with_fields => { template => "" });
    my $current_uri = $mech->uri->path;
    $mech->get_ok('/bookcovers?bare=1');
    my $body = $mech->content;
    my @found;
    while ($body =~ m{(/bookcovers/bc/(\d+)/edit)}g) {
        diag $1;
        push @found, $2;
    }
    is scalar(@found), 1, "Found only one cover";
    $mech->get_ok('/logout');
}
# admin
{
    $mech->get_ok('/login');
    $tuser->set_roles([
                       { role => 'admin' },
                       { role => 'librarian' },
                      ]);
    $mech->submit_form(with_fields => { __auth_user => 'bclib', __auth_pass => 'pallino' });
    $mech->get_ok('/bookcovers?bare=1');
    my $body = $mech->content;
    my @found;
    while ($body =~ m{(/bookcovers/bc/(\d+)/edit)}g) {
        diag $1;
        push @found, $2;
    }
    is scalar(@found), $site->bookcovers->count, "Found more covers: " . join(' ', @found);
    $mech->get_ok('/logout');
}
# root
{
    # change the bookcover ownership
    my $otherbc = $site->bookcovers->first;
    $otherbc->update({ site_id => '0blog0' });
    $mech->get_ok('/login');
    $tuser->set_roles([
                       { role => 'admin' },
                       { role => 'librarian' },
                       { role => 'root' },
                     ]);
    $mech->submit_form(with_fields => { __auth_user => 'bclib', __auth_pass => 'pallino' });
    $mech->get_ok('/bookcovers?bare=1');
    my $body = $mech->content;
    my @found;
    while ($body =~ m{(/bookcovers/bc/(\d+)/edit)}g) {
        diag $1;
        push @found, $2;
    }
    is scalar(@found), $site->bookcovers->count, "Found only sites: " . join(' ', @found);
    ok !scalar(grep { $_ == $otherbc->bookcover_id } @found), "bc from other site not found";
    $mech->get('/bookcovers/bc/' . $otherbc->bookcover_id . '/edit');
    is $mech->status, 404;
    $mech->get_ok('/logout');

    $mech->get('/bookcovers/bc/' . $otherbc->bookcover_id . '/edit');
    is $mech->status, 404;

    $mech->get_ok('/login');
    $tuser->set_roles([
                       { role => 'admin' },
                       { role => 'librarian' },
                     ]);
    $mech->submit_form(with_fields => { __auth_user => 'bclib', __auth_pass => 'pallino' });
    $mech->get('/bookcovers/bc/' . $otherbc->bookcover_id . '/edit');
    is $mech->status, 404;
}

{
    foreach my $bc ($site->bookcovers) {
        my $wd = $bc->working_dir;
        if ($wd->exists) {
            $bc->delete;
        }
        ok !$wd->exists, "$wd removed";
    }
}

{
    $site->bookcovers->create_and_initalize({
                                             created => DateTime->now(time_zone => 'UTC')->subtract(days => 2),
                                            });
    ok $schema->resultset('Bookcover')->expired->count;
    ok $schema->resultset('Bookcover')->purge_old_bookcovers;
}

diag "Testing CMYK conversion";
{
    my $bc = $site->bookcovers->create_and_initalize({ created => $now });
    my $wd = $bc->working_dir;
    path("t/color-profiles/sRGB2014.icc")->copy($wd->child('srgb.icc'));
    path("t/color-profiles/GRACoL2006_Coated1v2.icc")->copy($wd->child('cmyk.icc'));
    my $image = path("t/files/shot.jpg")->copy($wd->child("f1.jpeg"));
    my ($in, $out, $err);
    run([ identify => -format => '%r', "$image" ], \$in, \$out, \$err);
    like $out, qr{sRGB};
    $bc->update_from_params({
                             title_muse_str => "Title *title*",
                             author_muse_str => "Author *author*",
                             spinewidth => 10,
                             back_text_muse_body => "This\n\nIs\n\nThe *back*",
                             image_file => "f1.jpeg",
                             isbn_isbn => "9788899757410",
                            });
    my $outfile = $bc->write_tex_file;
    ok $outfile->exists;
    my ($isbn) = $wd->children(qr{isbn-.*\.pdf});
    ok $isbn;
    my $texbody = $outfile->slurp_utf8;
    like $texbody, qr{isbn.*\.pdf};
    my @logs;
    my $res = $bc->produce_pdf(sub { push @logs, @_ });
    ok $res->{success};
    diag Dumper(\@logs);
    is_deeply(\@logs, [
                       "Examining f1.jpeg\n",
                       "Colorspace is DirectClass sRGB \n",
                       "Converting to CMYK\n",
                      ]);
    run([ identify => -format => '%r', "$image" ], \$in, \$out, \$err);
    like $out, qr{CMYK};
}

{
    my $amech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'AmuseWikiFarm',
                                                    host => $site->canonical);
    $amech->get('/bookcovers');
    ok $amech->submit_form(with_fields => { __auth_human => 16 });
    my $found = 0;
    foreach my $bc ($schema->resultset('Bookcover')->all) {
        $amech->get('/bookcovers/bc/' . $bc->bookcover_id . '/edit');
        diag $amech->status;
        if ($amech->status ne '404') {
            $found++;
        }
    }
    is $found, 0, "Anonymous user can't find any bookcover";
    $amech->get('/bookcovers/create');
    my $current_path = $amech->uri->path;
    diag $amech->uri->path;
    $amech->submit_form(with_fields => {
                                        title_muse_str => '<em>Test Title</em> <b>Test Title</b>',
                                        author_muse_str => '<em>Test Author</em> <b>Test Author</b>',
                                        back_text_muse_body => '<em>Test Body</em> <b>Test Body</b>',
                                        comments => '<em>Test Comment</em> <b>Test Comment</b>',
                                        title => '<em>Test Name</em> <b>Test Name</b>',
                                        isbn_isbn => '<em>Test ISBN</em> <b>Test ISBN</b>',
                                       },
                        button => 'build',
                       );
    $amech->get($current_path);
    $amech->content_lacks("Test ISBN");
    foreach my $n (qw/Title Body Comment Name Author/) {
        $amech->content_lacks("<em>Test $n</em> <b>Test $n</b>");
        $amech->content_contains("&lt;em&gt;Test ${n}&lt;/em&gt; &lt;b&gt;Test ${n}&lt;/b&gt;")
          or die $amech->content;
    }
    $amech->get('/bookcovers');
    foreach my $n (qw/Comment Name/) {
        $amech->content_lacks("<em>Test $n</em> <b>Test $n</b>");
        $amech->content_contains("&lt;em&gt;Test ${n}&lt;/em&gt; &lt;b&gt;Test ${n}&lt;/b&gt;")
          or die $amech->content;
    }
    # at least check that it doesn't crash
    my $clone_path = $current_path;
    $clone_path =~ s/edit$/clone/;
    $amech->get_ok($clone_path);
    like $amech->uri->path, qr{\d+/edit$};
    isnt $amech->uri->path, $current_path;
    diag $amech->uri->path;
}

{
    my $bc = $site->bookcovers->first;
    is $bc->site_id, $site->id;
    my $j = $schema->resultset('Site')->find('0blog0')->jobs->enqueue(build_bookcover => { id => $bc->bookcover_id });
    $j->dispatch_job;
    like path($j->log_file)->slurp_utf8, qr/SUCCESS/;
}
