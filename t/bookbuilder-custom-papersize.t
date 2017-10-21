#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 17;
use Data::Dumper;
use AmuseWikiFarm::Archive::BookBuilder;

my $bb = AmuseWikiFarm::Archive::BookBuilder->new;

is($bb->papersize, 'generic');
is($bb->paper_width, 0);
is($bb->paper_height, 0);
is($bb->computed_papersize, '210mm:11in');

$bb->paper_width(200);
is($bb->computed_papersize, '210mm:11in');

$bb->paper_height(300);
is($bb->computed_papersize, '200mm:300mm');

is($bb->crop_papersize, 'a4');
is($bb->crop_paper_width, 0);
is($bb->crop_paper_height, 0);
is($bb->computed_crop_papersize, 'a4');

$bb->crop_paper_width(300);
is($bb->computed_crop_papersize, 'a4');

$bb->crop_paper_height(400);
is($bb->computed_crop_papersize, '300mm:400mm');

is ($bb->crop_paper_thickness, '0.10mm');
$bb->imposed(1);
$bb->crop_paper_thickness('0.15mm');

my $as_job = $bb->as_job;

is_deeply ($bb->as_job->{imposer_options},
           {
            schema => '2up',
            cover => 1,
           }, "Imposer options look ok");

is($bb->as_job->{template_options}->{papersize}, '200mm:300mm', "paper computed ok");


$bb->crop_marks(1);

is_deeply ($bb->as_job->{imposer_options},
           {
            schema => '2up',
            cover => 1,
            paper => '300mm:400mm',
            paper_thickness => '0.15mm',
           }, "Imposer options look ok for crop marks");

my $new_bb = AmuseWikiFarm::Archive::BookBuilder->new($bb->serialize);

is_deeply ($new_bb->as_job, $bb->as_job, "Cloning works");
