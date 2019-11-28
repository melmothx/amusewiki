#!perl

use utf8;
use strict;
use warnings;
use Test::More tests => 77;
BEGIN { $ENV{DBIX_CONFIG_DIR} = "t" };
use File::Spec::Functions qw/catdir catfile/;
use lib catdir(qw/t lib/);

use AmuseWiki::Tests qw/create_site/;
use AmuseWikiFarm::Schema;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use AmuseWikiFarm::Archive::BookBuilder;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $schema = AmuseWikiFarm::Schema->connect('amuse');
my $site_id = '0textattach0';
my $site = create_site($schema, $site_id);

my %titles;

foreach my $i (1..2) {
    my ($rev) = $site->create_new_text({ title => "$i Hello $i",
                                         textbody => '',
                                       }, 'text');
    my @body;
    foreach my $f (qw/shot.jpg shot.pdf shot.png big.jpeg/) {
        my $got = $rev->add_attachment(catfile(t => files => $f))->{attachment};
        ok $got and diag $got;
        $rev->edit($rev->muse_body . "\n\n[[$got]]\n\n");
        push @body, $got;
    }
    my @header;
    foreach my $f (qw/shot.jpg shot.pdf shot.png big.jpeg/) {
        my $got = $rev->add_attachment(catfile(t => files => $f))->{attachment};
        ok $got;
        push @header, $got;
    }
    $rev->edit("#ATTACH " . join(' ', @header) . "\n" . $rev->muse_body);
    my $cover;
    {
        $cover = $rev->add_attachment(catfile(t => files => 'shot.jpg'))->{attachment};
        ok $cover;
        $rev->edit("#cover $cover\n" . $rev->muse_body);
    }
    diag $rev->muse_body;
    $rev->commit_version;
    $rev->publish_text(sub { diag @_ });
    my $title = $rev->title;
    $titles{$title->uri} = {
                            body => [ sort @body ],
                            cover => [$cover],
                            header => [ sort @header ],
                           };
}

foreach my $uri (keys %titles) {
    my $data = $titles{$uri};
    my @attachments = map { @{$data->{$_}} } keys %$data;
    print Dumper \@attachments;
}

my $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                  job_id => 888888,
                                                 );

# use cover_from_archive with 2 files
foreach my $title ($site->titles->by_uri([ keys %titles ])->all) {
    diag $title->uri;
    # diag $title->muse_body;
    my @images = sort map { $_->uri } $title->images;
    my $spec = $titles{$title->uri};
    is scalar(@images), 3;

    is_deeply \@images, [ grep { /\.(png|jpg)$/ } @{$spec->{body}} ], "->images seems to work";

    my @all_images =  grep { /\.(png|jpg)$/ } (@{$spec->{body}}, @{$spec->{cover}}, @{$spec->{header}});

    is($title->attachments->images_only->count, scalar(@all_images)) or diag Dumper(\@all_images);

    my @all_atts = (@{$spec->{body}}, @{$spec->{cover}}, @{$spec->{header}});

    # File which was uploaded but not referenced ignored, we can't get it from parsing the body,
    # hence, -1.

    is($title->attachments->count, @all_atts - 1, "Attachment count is fine") or diag Dumper(\@all_atts);
    $bb->add_text($title->uri);
    $bb->cover_from_archive(${$spec->{cover}}[0]);
}

diag Dumper($bb->texts);
my @listed = @{$bb->related_attachments};
ok scalar(@listed), "Found the related attachments in the BB object";

ok $bb->valid_cover_from_archive;
$bb->compile;

check_cover($bb, $bb->cover_from_archive);

$bb->clear;

$bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                               job_id => 888889,
                                              );

# use cover_from_archive with 1 file
foreach my $title ($site->titles->all) {
    $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                   job_id => '888889' . $title->id,
                                                  );
    $bb->add_text($title->uri);
    my $cover = $title->attachments->images_only->first->uri;
    $bb->cover_from_archive($cover);
    ok $bb->compile;
    check_cover($bb, $bb->cover_from_archive);
    $bb->clear;
}

# normal upload, here we reusue the same image, but simulating an upload.
foreach my $title ($site->titles->all) {
    $bb = AmuseWikiFarm::Archive::BookBuilder->new(site => $site,
                                                   job_id => '888887' . $title->id,
                                                  );
    $bb->add_text($title->uri);
    $bb->add_file($title->attachments->images_only->first->f_full_path_name);
    diag $bb->coverfile;
    ok $bb->compile;
    check_cover($bb, $bb->coverfile);
    $bb->clear;
}

# check if by chance we nuked something
foreach my $uri (keys %titles) {
    my $data = $titles{$uri};
    my @attachments = map { @{$data->{$_}} } keys %$data;
    print Dumper(\@attachments);
    foreach my $att (@attachments) {
        ok $site->attachments->find({ uri => $att })->path_object->exists, "$att exists";
    }
}



sub check_cover {
    my ($bb, $cover_name) = @_;
    foreach my $f ($bb->produced_files) {
        diag "Produced $f";
        my $abs = File::Spec->catfile($bb->filedir, $f);
        ok (-f $abs, "msg: $f exists in $abs");
        if ($f =~ m/(.+)\.zip/) {
            diag "found the zip $1";
            my $extractor = Archive::Zip->new($abs);
            ok ($extractor->read($abs) == AZ_OK, "Zip can be read");
            my @files = $extractor->memberNames;
            my $produced = $bb->job_id . '.tex';
            my ($tex) = $extractor->membersMatching(qr{\Q$produced\E});
            unless ($tex) {
                ($tex) = $extractor->membersMatching(qr{\.tex$});
            }
            ok ($tex, "Found the tex source in the zip") or diag Dumper(\@files);
            my $tex_body = $extractor->contents($tex->fileName);
            like $tex_body, qr{\\vskip 3em\s*\\includegraphics\S+\{\Q$cover_name\E\}}s,
              "Used $cover_name for cover";
        }
    }
}
