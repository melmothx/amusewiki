use strict;
use warnings;
use utf8;
use Test::More tests => 227;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };

use Data::Dumper::Concise;
# use Test::Memory::Cycle;
use Try::Tiny;
use CAM::PDF;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

use AmuseWikiFarm::Schema;
use File::Basename qw/basename/;
use AmuseWikiFarm::Utils::Amuse qw/muse_filename_is_valid muse_naming_algo to_json from_json/;
use AmuseWikiFarm::Archive::BookBuilder;

my $pdftotext = system('pdftotext', '-v') == 0 ? 1 : 0;
my $schema = AmuseWikiFarm::Schema->connect('amuse');

ok (-d AmuseWikiFarm::Archive::BookBuilder->filedir, "Found " . AmuseWikiFarm::Archive::BookBuilder->filedir);

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 999998,
                                                      });
    my $token = $bb->generate_token;
    my $json = $bb->serialize_json;
    ok($token, "Token generated") and diag $token;
    ok($json, "json ok") and diag $json;
    ok !$bb->token;
    my $got_token = $bb->save_session;
    ok $bb->token, "Token generated";
    my $session = $bb->site->bookbuilder_sessions->from_token($bb->token);
    is $bb->token,  $session->token . '-' . $session->bookbuilder_session_id;
    is_deeply(from_json($session->bb_data), $bb->serialize);
    is_deeply(from_json($json), $bb->serialize, "json serialization is ok");
    cleanup($bb->job_id);
    $bb->mainfont('TeX Gyre Pagella');

    for my $format (qw/pdf pdf epub/) {
        $bb->format($format);
        $bb->add_text('first-test');
        if ($format eq 'pdf') {
            my $pdffile = File::Spec->catfile($bb->filedir,
                                          $bb->compile);
            my $pdf = CAM::PDF->new($pdffile);
            my ($font) = ($pdf->getFonts(1));
            ok $font->{BaseFont}->{value},
              "Found font name: $font->{BaseFont}->{value}";
            like $font->{BaseFont}->{value}, qr/Pagella/, "Font is correct";
        }
        elsif ($format eq 'epub') {
            my $epub = File::Spec->catfile($bb->filedir,
                                           $bb->compile);
            unless ($epub =~ m/\.epub/) {
                # horrid
                delete $bb->{dbic};
                delete $bb->{site};
                die Dumper($bb);
            }
            ok (-f $epub);
            my $tmpdir = File::Temp->newdir(CLEANUP => 1);
            my $zip = Archive::Zip->new;
            die "Couldn't read $epub" if $zip->read($epub) != AZ_OK;
            $zip->extractTree('OPS', $tmpdir->dirname) == AZ_OK
              or die "Couldn't extract $epub OPS into " . $tmpdir->dirname ;
            my @files = grep { /\.(otf|ttf)$/ } $zip->memberNames;
            ok (@files, "Found embedded files");
        }
        like $bb->mainfont, qr/Pagella/;
    }
}

my $bb = AmuseWikiFarm::Archive::BookBuilder->new;

my @list = (qw/a-a
               a-b-c
               bla-bla-bla
               ciao-cioa
              /);

push @list, 'a' x 95;

foreach my $valid (@list) {
    ok($bb->add_text($valid), "Valid: $valid");
    is($valid, muse_naming_algo($valid), "Double check: $valid");
}

@list = (qw/-a-a-a-
            blabla|bla
            aa
            /);

push @list, 'klasd laskdf alsdkfj';
push @list, 'a' x 96;

push @list, 'àààà';
push @list, 'l2()';
push @list, '1234-';
push @list, '/etc/passwd-';
push @list, '1234,1234';
push @list, '1l239z .-asdf asdf';

foreach my $invalid (@list) {
    ok(!$bb->add_text($invalid), "Not valid: $invalid");
    ok($invalid ne muse_naming_algo($invalid), "Double check invalid: $invalid");
}

eval {
    $bb->textlist(undef);
};

ok $@, "Putting undef in textlist raises an exception: " . $@->message;

$bb->delete_all;
ok($bb->add_text('my-good-text'));
ok($bb->add_text('ciao'));
ok($bb->add_text('/etc/passwd:1,2,3'));
is_deeply $bb->textlist, ['my-good-text', 'ciao', 'passwd:1,2,3'], "Texts added correctly";

is $bb->total_texts, 3;

$bb->delete_text(3);
$bb->delete_text(1);
is_deeply $bb->textlist, [qw/ciao/], "Text removed correctly";

$bb->move_down(1);
is_deeply $bb->textlist, [qw/ciao/], "Nothing happens";

$bb->move_up(1);
is_deeply $bb->textlist, [qw/ciao/], "Nothing happens";

$bb->add_text('appended');
is_deeply $bb->textlist, [qw/ciao appended/], "Text added";

$bb->move_down(1);
is_deeply $bb->textlist, [qw/appended ciao/], "Text swapped";

diag "Testing the moving up";
$bb->move_up(2);

is_deeply $bb->textlist, [qw/ciao appended/], "Text swapped";

$bb->delete_all;
is_deeply $bb->textlist, [], "Texts purged";


my @accessors = (
                 [ twoside => 'lkasdf', 0],
                 [ twoside => undef, undef],
                 [ papersize => 'lasdf', 'generic'],
                 [ papersize => 'a4', 'a4'],
                 [ division => '4', 12],
                 [ division => '15', 15],
                 [ fontsize => '8', 10],
                 [ fontsize => '12', 12],
                 [ fontsize => '10.5', 12],
                 [ bcor => '', '0'],
                 [ bcor => 'blabla', '0'],
                 [ bcor => '10', '10'],
                 [ mainfont => 'Charis SIL', 'Charis SIL'],
                 [ mainfont => 'Linux Libertine O', 'Linux Libertine O'],
                 [ mainfont => '\hello', 'Linux Libertine O'],
                 [ opening => '\\blabla', 'any' ],
                 [ opening => 'right', 'right' ],
                 [ opening => 'any', 'any' ],
                );
foreach my $try (@accessors) {
    my $method   = $try->[0];
    my $input    = $try->[1];
    my $expected = $try->[2];
    try {
        $bb->$method($input);
    } catch {
        my $msg = $_->message;
        chomp $msg;
        diag $msg;
    };
    my $show = Dumper($expected);
    chomp $show;
    is ($bb->$method, $expected, "$method returned $show");
}

eval { $bb->schema('2x4x2x') };
my $err = $@;

ok($err->message, "Found error") and diag $err->message;

eval { $bb->schema('2x4x2') };

ok(!$@, "No error");

eval { $bb->papersize('blablabla') };
ok($@, "Error found") and diag $@->message;


eval { $bb->papersize('a4') };
ok(!$@, "No error");

diag Dumper($bb);


my $expected = {
                'text_list' => [
                                'appended',
                                'pippo'
                               ],
                'imposer_options' => {
                                      'signature' => '40-80',
                                      'schema' => '2up',
                                      'cover'  => '1',
                                     },
                'template_options' => {
                                       'bcor' => '20mm',
                                       'nocoverpage' => 1,
                                       'notoc' => 1,
                                       nofinalpage => undef,
                                       'mainfont' => 'CMU Serif',
                                       sansfont    => undef,
                                       monofont    => undef,
                                       beamertheme => 'default',
                                       beamercolortheme => 'dove',
                                       'twoside' => 1,
                                       'division' => 14,
                                       'fontsize' => 10,
                                       'coverwidth' => '0.85',
                                       'papersize' => 'a4',
                                       'cover' => undef,
                                       opening => 'right',
                                       headings => 0,
                                      },
                'title' => 'Pippuzzo *va* in **montagna**'
               };


my %params = (
              title       => 'Pippuzzo *va* in **montagna**',
              mainfont    => 'CMU Serif',
              fontsize    => '10',
              papersize   => 'a4',
              division    => '14',
              bcor        => '20',
              coverwidth  => '85',
              twoside     => 1,
              notoc       => 1,
              nocoverpage => 1,
              imposed     => 1,
              signature_2up   => '40-80',
              schema      => '2up',
              cover       => 1,
              # coverfile should be called with add_file
              coverfile   => 'garbage',
              opening     => 'right',
          );

$bb = AmuseWikiFarm::Archive::BookBuilder->new;

foreach my $text (qw/appended pippo/) {
    ok($bb->add_text($text), "$text added");
}

$bb->import_from_params(%params);
is $bb->coverfile, undef, 'coverfile not imported';

is_deeply ($bb->as_job, $expected, "Output correct");

my $newbb = AmuseWikiFarm::Archive::BookBuilder->new(%{$bb->serialize});

is_deeply ($bb->as_job, $newbb->as_job, "Old and new have the same output");

is($bb->as_job->{title}, $params{title});

is ($bb->opening, 'right');

%params = (
           title       => 'Pippuzzo *va* in **montagna**',
           mainfont    => 'CMU Serif',
           fontsize    => '10',
           papersize   => 'a4',
           division    => '14',
           bcor        => '20',
           coverwidth  => '85',
           twoside     => 1,
           notoc       => 1,
           nocoverpage => 1,
           imposed     => 1,
           signature_2up   => '40-80',
           signature_4up => '8',
           schema      => '2up',
           cover       => 1,
           opening     => 'any',
           # coverimage should be called with add_file
          );

$bb->import_from_params(%params);
is $bb->signature_in_use, '40-80', "Signature_4up ignored with schema 2up";
is $bb->opening, 'any';

%params = (
           title       => 'Pippuzzo *va* in **montagna**',
           mainfont    => 'CMU Serif',
           fontsize    => '10',
           papersize   => 'a4',
           division    => '14',
           bcor        => '20',
           coverwidth  => '85',
           twoside     => 1,
           notoc       => 1,
           nocoverpage => 1,
           imposed     => 1,
           signature_2up   => '4',
           signature_4up => '16',
           schema      => '4up',
           cover       => 1,
           opening     => '<em>',
           format => 'pdf',
          );

$bb->import_from_params(%params);
is $bb->signature_in_use, 16, "Signature_4up picked up with 4up schema";
is $bb->opening, 'any', "Opening set to any because of invalid input";

is $bb->mainfont, 'CMU Serif';
$bb->import_from_params();
is $bb->imposed, undef, "imposed nulled out with empty params";
is $bb->mainfont, undef, "mainfont undef with empty params";
is $bb->notoc, undef, "notoc set to undef";
is $bb->twoside, undef, "twoside set to undef";

$bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                dbic => $schema,
                                                site_id => '0blog0',
                                                job_id => 999999,
                                               });

is ($bb->site_id, '0blog0', "Object ok");
is ($bb->site->id, '0blog0', "site built");

$bb->site->update({ bb_page_limit => 15 });

my @check_added;
foreach my $text ($bb->site->titles->published_texts) {
    ok ($bb->add_text($text->uri), "Added " . $text->uri);
    push @check_added, $text->uri;
    ok (!$bb->error, "No error found") or diag $bb->error;
}
ok (!$bb->add_text('this-does-not-exists'));
ok ($bb->error, "Found error: " . $bb->error);

ok ($bb->total_pages_estimated,
    "Found page estimated: " . $bb->total_pages_estimated);

is_deeply ($bb->texts, \@check_added, "List ok");

$bb->format('epub');
check_file($bb, "epub");

my %titlepage = (
                 subtitle => '*my* subtitle',
                 author => '*my* author',
                 date => '*my* date',
                 notes => '*my* notes',
                 source => '*my* source',
                );
$bb->import_from_params(%params,
                        %titlepage,
                       );

is_deeply({ $bb->_muse_virtual_headers }, { title => $params{title}, %titlepage });
foreach my $k (keys %titlepage) {
    is $bb->$k, $titlepage{$k}, "$k is $titlepage{$k}";
}

ok (!$bb->epub);
# readd
$bb->delete_text(3);

$bb->site->update({ bb_page_limit => 30 });

foreach my $text(qw/first-test do-this-by-yourself/) {
    ok ($bb->add_text($text), "Added $text again") or diag $bb->error;
}
ok ($bb->imposed, "Imposing required");
$bb->schema('2up');
$bb->signature_2up(0);
$bb->cover(1);
check_file($bb, "imposed one");
cleanup($bb->job_id);

$bb->site->update({ bb_page_limit => 10 });

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 666666,
                                                       notoc => 1,
                                                      });
    ok($bb->add_text('first-test:1,pre,post'));
    is_deeply ($bb->texts,
               [ 'first-test:1,pre,post' ]);
    is $bb->total_texts, 1;
    my $pdf = check_file($bb, "Partial");
  SKIP: {
        skip "Missing pdftotext", 3, unless $pdftotext;
        my $pdftext = pdf_content($pdf);
        like $pdftext, qr{second chapter};
        unlike $pdftext, qr{second chapter.*second chapter}s;
        unlike $pdftext, qr{first chapter};
    }
}
{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 666667,
                                                       notoc => 1,
                                                      });
    $titlepage{title} = "*My* title";
    foreach my $k (keys %titlepage) {
        $bb->$k($titlepage{$k});
    }
    ok($bb->add_text('first-test:1,pre,post'));
    ok($bb->add_text('first-test:1'));
    is_deeply ($bb->texts,
               [ 'first-test:1,pre,post',
                 'first-test:1' ]);
    is $bb->total_texts, 2;
    my $pdf = check_file($bb, "Partial 2");
  SKIP: {
        skip "Missing pdftotext", 8, unless $pdftotext;
        my $pdftext = pdf_content($pdf);
        like $pdftext, qr{second chapter.*second chapter}s;
        unlike $pdftext, qr{first chapter};
        foreach my $titlepage_value (values %titlepage) {
            $titlepage_value =~ s/\*//g;
            like $pdftext, qr{\Q$titlepage_value\E}, "Found $titlepage_value";
        }
    }
}

{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 666699,
                                                       imposed => 1,
                                                       schema => '2up',
                                                       signature_2up => 0,
                                                       papersize => 'b6',
                                                       crop_papersize => 'a5',
                                                       crop_marks => 1,
                                                      });
    ok($bb->add_text('first-test'));
    my $pdf = check_file($bb, "cropmarks");
  SKIP: {
        skip "Missing pdftotext", 3, unless $pdftotext;
        my $pdftext = pdf_content($pdf);
        like $pdftext, qr{666699\.pdf}, "Found marker";
        like $pdftext, qr{Pg\s+0008}, "Found page marker";
        like $pdftext, qr{page 4 \#1/4}, "Found signature marker";
    }

}


{
    my $bb = AmuseWikiFarm::Archive::BookBuilder->new({
                                                       dbic => $schema,
                                                       site_id => '0blog0',
                                                       job_id => 666791,
                                                       imposed => 1,
                                                       schema => '2up',
                                                       signature_2up => 0,
                                                       papersize => 'b6',
                                                       crop_papersize => 'a5',
                                                       crop_marks => 1,
                                                       unbranded => 1,
                                                      });
    ok($bb->add_text('first-test'));
    my $pdf = check_file($bb, "unbranded");
  SKIP: {
        skip "Missing pdftotext", 3, unless $pdftotext;
        my $pdftext = pdf_content($pdf);
        like $pdftext, qr{666791\.pdf}, "Found marker";
        like $pdftext, qr{Pg\s+0008}, "Found page marker";
        like $pdftext, qr{page 4 \#1/4}, "Found signature marker";
    }

}



sub pdf_content {
    my $pdf = shift;
    my $txt = $pdf;
    $txt =~ s/\.pdf$/.txt/;
    system(pdftotext => $pdf) == 0 or die 'pdftotext failed $?';
    local $/ = undef;
    open (my $fh, '<', $txt) or die "cannot open $txt $!";
    my $ex = <$fh>;
    close $fh;
    unlink $txt;
    return $ex;
}


sub check_file {
    my ($bb, $msg) = @_;
    my $total_pages = $bb->total_pages_estimated;
    ok ($total_pages, "Total pages: $total_pages");
    my $out = $bb->compile;
    ok ($out, "$msg: $out produced");
    my $check_logo;
    if (my $site = $bb->site) {
        if (my $logo = $site->logo) {
            $check_logo = basename($logo);
        }
    }
    my $file = File::Spec->catfile($bb->filedir, $out);
    ok (-f $file, "$msg: $out: $file exists");
    foreach my $f ($bb->produced_files) {
        my $abs = File::Spec->catfile($bb->filedir, $f);
        ok (-f $abs, "$msg: $f exists in $abs");
        if ($f =~ m/(.+)\.zip/) {
            diag "found the zip $1";
            my $extractor = Archive::Zip->new($abs);
            ok ($extractor->read($abs) == AZ_OK, "Zip can be read");
            my @files = $extractor->memberNames;
            {
                ok (scalar(grep { /\.muse$/ } @files), "Found the muse sources")
                  or diag Dumper(\@files);
            }
            {
                ok (!scalar(grep { /\.imp.pdf$/ } @files),
                    "No stray imp file found")
                  or diag Dumper(\@files);
            }
            if ($check_logo) {
                diag "Checking logo";
                my @logos = grep { /\Q$check_logo\E/ } @files;
                if ($bb->unbranded) {
                    ok (!scalar(@logos),  "Not expected $check_logo in the source");
                }
                else {
                    ok (scalar(@logos),  "Found $check_logo in the source");
                }
                if ($bb->format eq 'pdf') {
                    my $produced = $bb->job_id . '.tex';
                    my $tex;
                    if ($bb->is_collection) {
                        # tex rewritten
                        ($tex) = $extractor->membersMatching(qr{\Q$produced\E$});
                    }
                    else {
                        # one and only
                        ($tex) = $extractor->membersMatching(qr{\.tex$});
                    }
                    ok ($tex, "Found the tex source in the zip") or diag Dumper(\@files);
                    my $tex_body = $extractor->contents($tex->fileName);
                    my $site_name = $bb->site->canonical;
                    foreach my $search ($check_logo,
                                        $bb->site->canonical,
                                        $bb->site->sitename,
                                        $bb->site->siteslogan) {
                        if ($search) {
                            diag "Checking $search in $tex";
                            if ($bb->unbranded) {
                                unlike $tex_body, qr{\Q$search\E},
                                  "$search not found in unbranded";
                            }
                            else {
                                like $tex_body, qr{\Q$search\E},
                                  "$search found in unbranded";
                            }
                        }
                    }
                }
            }
        }
    }
    return $file;
    # unlink $file or die $1;
}

sub cleanup {
    my $id = shift;
    my @files = ("$id.pdf", "$id.epub", "bookbuilder-$id.zip");
    foreach my $file (@files) {
        my $path = File::Spec->catfile(bbfiles => , $file);
        if (-f $path) {
            diag "removing $path";
            unlink $path or die $!;
        }
    }
}
